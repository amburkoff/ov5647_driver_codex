#include <linux/delay.h>
#include <linux/gpio.h>
#include <linux/i2c.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/mutex.h>
#include <linux/of_device.h>
#include <linux/of_gpio.h>
#include <linux/regmap.h>

#include <media/camera_common.h>
#include <media/media-entity.h>
#include <media/sensor_common.h>
#include <media/tegra-v4l2-camera.h>
#include <media/tegracam_core.h>
#include <media/v4l2-async.h>
#include <media/v4l2-ctrls.h>

#define OV5647_NAME			"nv_ov5647"
#define OV5647_DEFAULT_MCLK		"extperiph1"
#define OV5647_DEFAULT_AVDD_SUPPLY	"vana"
#define OV5647_DEFAULT_DVDD_SUPPLY	"vdig"
#define OV5647_DEFAULT_IOVDD_SUPPLY	"vif"
#define OV5647_GPIO_NOT_PRESENT		UINT_MAX

#define OV5647_TABLE_WAIT_MS		0xfffe
#define OV5647_TABLE_END		0xffff

#define OV5647_REG_CHIP_ID_HIGH		0x300a
#define OV5647_REG_CHIP_ID_LOW		0x300b
#define OV5647_REG_SW_RESET		0x0103
#define OV5647_REG_MODE_SELECT		0x0100
#define OV5647_REG_FRAME_OFF_NUMBER	0x4202
#define OV5647_REG_MIPI_CTRL00		0x4800
#define OV5647_REG_MIPI_CTRL14		0x4814
#define OV5640_REG_PAD_OUT		0x300d

#define OV5647_MODE_STANDBY		0x00
#define OV5647_MODE_STREAMING		0x01
#define OV5647_CHIP_ID			0x5647

#define OV5647_MIPI_CTRL00_CLOCK_LANE_GATE	BIT(5)
#define OV5647_MIPI_CTRL00_LINE_SYNC_ENABLE	BIT(4)
#define OV5647_MIPI_CTRL00_BUS_IDLE		BIT(2)
#define OV5647_MIPI_CTRL00_CLOCK_LANE_DISABLE	BIT(0)

struct ov5647_mode {
	const char *name;
	u32 width;
	u32 height;
	u32 code;
	const struct reg_8 *table;
};

struct ov5647 {
	struct i2c_client *client;
	struct tegracam_device *tc_dev;
	struct camera_common_data *s_data;
	struct mutex lock;
	u32 chip_id;
	bool board_setup_done;
	bool v4l2_registered;
};

static bool register_i2c_driver;
module_param(register_i2c_driver, bool, 0644);
MODULE_PARM_DESC(register_i2c_driver,
		 "Register the OV5647 i2c driver on module load. Default: false");

static bool allow_hw_probe;
module_param(allow_hw_probe, bool, 0644);
MODULE_PARM_DESC(allow_hw_probe,
			 "Allow real OV5647 probe and board setup when a DT match exists. Default: false");

static bool skip_v4l2_register;
module_param(skip_v4l2_register, bool, 0644);
MODULE_PARM_DESC(skip_v4l2_register,
		 "Probe sensor and chip ID but skip tegracam_v4l2subdev_register(). Default: false");

static bool skip_v4l2_unregister;
module_param(skip_v4l2_unregister, bool, 0644);
MODULE_PARM_DESC(skip_v4l2_unregister,
		 "Diagnostic only: skip tegracam_v4l2subdev_unregister() in remove(). Default: false");

static bool split_v4l2_unregister;
module_param(split_v4l2_unregister, bool, 0644);
MODULE_PARM_DESC(split_v4l2_unregister,
		 "Diagnostic only: inline V4L2 unregister phases with markers. Default: false");

static uint unload_marker_delay_ms;
module_param(unload_marker_delay_ms, uint, 0644);
MODULE_PARM_DESC(unload_marker_delay_ms,
		 "Optional delay after unload markers to let userspace persist logs. Default: 0");

static bool driver_registered;

static void ov5647_unload_marker_delay(void)
{
	if (unload_marker_delay_ms)
		msleep(unload_marker_delay_ms);
}

static void ov5647_split_v4l2subdev_unregister(struct tegracam_device *tc_dev)
{
	struct camera_common_data *s_data = tc_dev->s_data;
	struct v4l2_subdev *sd;

	if (!s_data) {
		dev_warn(tc_dev->dev,
			 "%s: s_data is NULL, skipping split unregister\n",
			 __func__);
		return;
	}

	sd = &s_data->subdev;

	dev_info(tc_dev->dev, "%s: before v4l2_ctrl_handler_free\n",
		 __func__);
	ov5647_unload_marker_delay();
	v4l2_ctrl_handler_free(s_data->ctrl_handler);
	dev_info(tc_dev->dev, "%s: after v4l2_ctrl_handler_free\n",
		 __func__);

#if IS_ENABLED(CONFIG_V4L2_ASYNC)
	dev_info(tc_dev->dev, "%s: before v4l2_async_unregister_subdev\n",
		 __func__);
	ov5647_unload_marker_delay();
	v4l2_async_unregister_subdev(sd);
	dev_info(tc_dev->dev, "%s: after v4l2_async_unregister_subdev\n",
		 __func__);
#else
	dev_info(tc_dev->dev, "%s: CONFIG_V4L2_ASYNC is disabled\n",
		 __func__);
#endif

#if IS_ENABLED(CONFIG_MEDIA_CONTROLLER)
	dev_info(tc_dev->dev, "%s: before media_entity_cleanup\n", __func__);
	ov5647_unload_marker_delay();
	media_entity_cleanup(&sd->entity);
	dev_info(tc_dev->dev, "%s: after media_entity_cleanup\n", __func__);
#else
	dev_info(tc_dev->dev, "%s: CONFIG_MEDIA_CONTROLLER is disabled\n",
		 __func__);
#endif
}

static const struct reg_8 ov5647_common_regs[] = {
	{0x0100, 0x00},
	{0x0103, 0x01},
	{0x3034, 0x1a},
	{0x3035, 0x21},
	{0x303c, 0x11},
	{0x3106, 0xf5},
	{0x3827, 0xec},
	{0x370c, 0x03},
	{0x5000, 0x06},
	{0x5003, 0x08},
	{0x5a00, 0x08},
	{0x3000, 0x00},
	{0x3001, 0x00},
	{0x3002, 0x00},
	{0x3016, 0x08},
	{0x3017, 0xe0},
	{0x3018, 0x44},
	{0x301c, 0xf8},
	{0x301d, 0xf0},
	{0x3a18, 0x00},
	{0x3a19, 0xf8},
	{0x3c01, 0x80},
	{0x3b07, 0x0c},
	{0x3630, 0x2e},
	{0x3632, 0xe2},
	{0x3633, 0x23},
	{0x3634, 0x44},
	{0x3636, 0x06},
	{0x3620, 0x64},
	{0x3621, 0xe0},
	{0x3600, 0x37},
	{0x3704, 0xa0},
	{0x3703, 0x5a},
	{0x3715, 0x78},
	{0x3717, 0x01},
	{0x3731, 0x02},
	{0x370b, 0x60},
	{0x3705, 0x1a},
	{0x3f05, 0x02},
	{0x3f06, 0x10},
	{0x3f01, 0x0a},
	{0x3a08, 0x01},
	{0x3a0f, 0x58},
	{0x3a10, 0x50},
	{0x3a1b, 0x58},
	{0x3a1e, 0x50},
	{0x3a11, 0x60},
	{0x3a1f, 0x28},
	{0x4001, 0x02},
	{0x4000, 0x09},
	{0x3503, 0x03},
	{ OV5647_TABLE_END, 0x00 },
};

static const struct reg_8 ov5647_sensor_oe_enable_regs[] = {
	{0x3000, 0x0f},
	{0x3001, 0xff},
	{0x3002, 0xe4},
	{ OV5647_TABLE_END, 0x00 },
};

static const struct reg_8 ov5647_sensor_oe_disable_regs[] = {
	{0x3000, 0x00},
	{0x3001, 0x00},
	{0x3002, 0x00},
	{ OV5647_TABLE_END, 0x00 },
};

static const struct reg_8 ov5647_mode0_640x480_10bpp[] = {
	{0x3036, 0x46},
	{0x3821, 0x01},
	{0x3820, 0x41},
	{0x3612, 0x59},
	{0x3618, 0x00},
	{0x3814, 0x35},
	{0x3815, 0x35},
	{0x3708, 0x64},
	{0x3709, 0x52},
	{0x3800, 0x00},
	{0x3801, 0x10},
	{0x3802, 0x00},
	{0x3803, 0x00},
	{0x3804, 0x0a},
	{0x3805, 0x2f},
	{0x3806, 0x07},
	{0x3807, 0x9f},
	{0x3808, 0x02},
	{0x3809, 0x80},
	{0x380a, 0x01},
	{0x380b, 0xe0},
	{0x380c, 0x07}, /* HTS = 1852, upstream VGA timing */
	{0x380d, 0x3c},
	{0x380e, 0x01}, /* VTS = 0x01f8, upstream VGA timing */
	{0x380f, 0xf8},
	{0x3a09, 0x2e},
	{0x3a0a, 0x00},
	{0x3a0b, 0xfb},
	{0x3a0d, 0x02},
	{0x3a0e, 0x01},
	{0x4004, 0x02},
	{0x4800, 0x34},
	{ OV5647_TABLE_END, 0x00 },
};

static const int ov5647_30fps[] = {
	30,
};

static const struct camera_common_frmfmt ov5647_frmfmt[] = {
	{
		.size = {
			.width = 640,
			.height = 480,
		},
		.framerates = ov5647_30fps,
		.num_framerates = ARRAY_SIZE(ov5647_30fps),
		.hdr_en = false,
		.mode = 0,
	},
};

static const struct ov5647_mode ov5647_modes[] = {
	{
		.name = "640x480-10bpp-30fps",
		.width = 640,
		.height = 480,
		.code = MEDIA_BUS_FMT_SBGGR10_1X10,
		.table = ov5647_mode0_640x480_10bpp,
	},
};

static const u32 ov5647_ctrl_cid_list[] = {
	TEGRA_CAMERA_CID_GAIN,
	TEGRA_CAMERA_CID_EXPOSURE,
	TEGRA_CAMERA_CID_FRAME_RATE,
	TEGRA_CAMERA_CID_SENSOR_MODE_ID,
};

static const struct regmap_config ov5647_regmap_config = {
	.reg_bits = 16,
	.val_bits = 8,
	.cache_type = REGCACHE_RBTREE,
	.max_register = 0xffff,
};

static inline struct ov5647 *to_ov5647(struct tegracam_device *tc_dev)
{
	return tegracam_get_privdata(tc_dev);
}

static inline struct ov5647 *s_data_to_ov5647(struct camera_common_data *s_data)
{
	if (!s_data || !to_tegracam_device(s_data))
		return NULL;

	return to_ov5647(to_tegracam_device(s_data));
}

static int ov5647_write_reg(struct camera_common_data *s_data, u16 addr, u8 val)
{
	struct ov5647 *priv = s_data_to_ov5647(s_data);
	struct i2c_client *client;
	u8 buf[3];
	int err;

	if (!priv || !s_data)
		return -EINVAL;

	client = priv->client;
	if (!client)
		return -ENODEV;

	buf[0] = addr >> 8;
	buf[1] = addr & 0xff;
	buf[2] = val;

	err = i2c_master_send(client, buf, sizeof(buf));
	if (err == sizeof(buf))
		err = 0;
	else if (err >= 0)
		err = -EIO;

	if (err)
		dev_err(s_data->dev,
			"%s: reg write failed addr=0x%04x val=0x%02x err=%d\n",
			__func__, addr, val, err);
	else
		dev_dbg(s_data->dev, "%s: addr=0x%04x val=0x%02x\n",
			__func__, addr, val);

	return err;
}

static int ov5647_read_reg(struct camera_common_data *s_data, u16 addr, u8 *val)
{
	struct ov5647 *priv = s_data_to_ov5647(s_data);
	struct i2c_client *client;
	struct i2c_msg msgs[2];
	u8 addr_buf[2];
	u8 reg_val;
	int err;

	if (!priv || !s_data || !val)
		return -EINVAL;

	client = priv->client;
	if (!client)
		return -ENODEV;

	addr_buf[0] = addr >> 8;
	addr_buf[1] = addr & 0xff;

	msgs[0].addr = client->addr;
	msgs[0].flags = 0;
	msgs[0].len = sizeof(addr_buf);
	msgs[0].buf = addr_buf;

	msgs[1].addr = client->addr;
	msgs[1].flags = I2C_M_RD;
	msgs[1].len = sizeof(reg_val);
	msgs[1].buf = &reg_val;

	err = i2c_transfer(client->adapter, msgs, ARRAY_SIZE(msgs));
	if (err == ARRAY_SIZE(msgs))
		err = 0;
	else if (err >= 0)
		err = -EIO;

	if (err) {
		dev_err(s_data->dev,
			"%s: reg read failed addr=0x%04x err=%d\n",
			__func__, addr, err);
		return err;
	}

	*val = reg_val;
	dev_dbg(s_data->dev, "%s: addr=0x%04x val=0x%02x\n",
		__func__, addr, *val);

	return 0;
}

static int ov5647_write_table(struct camera_common_data *s_data,
			      const struct reg_8 *table)
{
	int err;

	for (; table->addr != OV5647_TABLE_END; table++) {
		if (table->addr == OV5647_TABLE_WAIT_MS) {
			msleep(table->val);
			continue;
		}

		err = ov5647_write_reg(s_data, table->addr, table->val);
		if (err)
			return err;
	}

	return 0;
}

static int ov5647_write_stream_stop_regs(struct camera_common_data *s_data,
					 bool standby)
{
	int err;

	err = ov5647_write_reg(s_data, OV5647_REG_MIPI_CTRL00,
			       OV5647_MIPI_CTRL00_CLOCK_LANE_GATE |
			       OV5647_MIPI_CTRL00_BUS_IDLE |
			       OV5647_MIPI_CTRL00_CLOCK_LANE_DISABLE);
	if (err)
		return err;

	err = ov5647_write_reg(s_data, OV5647_REG_FRAME_OFF_NUMBER, 0x0f);
	if (err)
		return err;

	err = ov5647_write_reg(s_data, OV5640_REG_PAD_OUT, 0x01);
	if (err)
		return err;

	if (!standby)
		return 0;

	return ov5647_write_reg(s_data, OV5647_REG_MODE_SELECT,
				OV5647_MODE_STANDBY);
}

static struct camera_common_pdata *ov5647_parse_dt(struct tegracam_device *tc_dev)
{
	struct device *dev = tc_dev->dev;
	struct device_node *np = dev->of_node;
	struct camera_common_pdata *pdata;
	int gpio;

	dev_info(dev, "%s: enter\n", __func__);

	if (!np) {
		dev_err(dev, "%s: device tree node is missing\n", __func__);
		return NULL;
	}

	pdata = devm_kzalloc(dev, sizeof(*pdata), GFP_KERNEL);
	if (!pdata)
		return NULL;

	pdata->mclk_name = OV5647_DEFAULT_MCLK;
	pdata->reset_gpio = OV5647_GPIO_NOT_PRESENT;
	pdata->pwdn_gpio = OV5647_GPIO_NOT_PRESENT;
	pdata->af_gpio = OV5647_GPIO_NOT_PRESENT;
	pdata->use_cam_gpio = true;
	pdata->regulators.avdd = OV5647_DEFAULT_AVDD_SUPPLY;
	pdata->regulators.dvdd = OV5647_DEFAULT_DVDD_SUPPLY;
	pdata->regulators.iovdd = OV5647_DEFAULT_IOVDD_SUPPLY;

	of_property_read_string(np, "mclk", &pdata->mclk_name);
	of_property_read_string(np, "avdd-reg", &pdata->regulators.avdd);
	of_property_read_string(np, "dvdd-reg", &pdata->regulators.dvdd);
	of_property_read_string(np, "iovdd-reg", &pdata->regulators.iovdd);

	gpio = of_get_named_gpio(np, "reset-gpios", 0);
	if (gpio >= 0)
		pdata->reset_gpio = gpio;

	gpio = of_get_named_gpio(np, "pwdn-gpios", 0);
	if (gpio >= 0)
		pdata->pwdn_gpio = gpio;

	dev_info(dev,
		 "%s: pdata=%p mclk=%s reset_gpio=%d pwdn_gpio=%d avdd=%s dvdd=%s iovdd=%s\n",
		 __func__, pdata, pdata->mclk_name,
		 (int)pdata->reset_gpio, (int)pdata->pwdn_gpio,
		 pdata->regulators.avdd ?: "unset",
		 pdata->regulators.dvdd ?: "unset",
		 pdata->regulators.iovdd ?: "unset");

	return pdata;
}

static int ov5647_power_get(struct tegracam_device *tc_dev)
{
	struct device *dev = tc_dev->dev;
	struct ov5647 *priv = to_ov5647(tc_dev);
	struct camera_common_data *s_data = tc_dev->s_data;
	struct camera_common_pdata *pdata;
	struct camera_common_power_rail *pw;
	int err;

	dev_info(dev, "%s: enter priv=%p s_data=%p pdata=%p\n",
		 __func__, priv, s_data, s_data ? s_data->pdata : NULL);

	if (!priv) {
		dev_err(dev, "%s: priv is NULL\n", __func__);
		return -EINVAL;
	}

	if (!s_data) {
		dev_err(dev, "%s: s_data is NULL\n", __func__);
		return -EINVAL;
	}

	if (!s_data->pdata) {
		dev_err(dev, "%s: s_data->pdata is NULL\n", __func__);
		return -EINVAL;
	}

	if (!s_data->power) {
		dev_err(dev, "%s: s_data->power is NULL\n", __func__);
		return -EINVAL;
	}

	pdata = s_data->pdata;
	pw = s_data->power;
	pw->reset_gpio = pdata->reset_gpio;
	pw->pwdn_gpio = pdata->pwdn_gpio;

	if (pdata->regulators.avdd) {
		err = camera_common_regulator_get(dev, &pw->avdd,
						  pdata->regulators.avdd);
		if (err) {
			dev_err(dev, "%s: avdd get failed err=%d\n", __func__, err);
			return err;
		}
	}

	if (pdata->regulators.dvdd) {
		err = camera_common_regulator_get(dev, &pw->dvdd,
						  pdata->regulators.dvdd);
		if (err) {
			dev_err(dev, "%s: dvdd get failed err=%d\n", __func__, err);
			return err;
		}
	}

	if (pdata->regulators.iovdd) {
		err = camera_common_regulator_get(dev, &pw->iovdd,
						  pdata->regulators.iovdd);
		if (err) {
			dev_err(dev, "%s: iovdd get failed err=%d\n", __func__, err);
			return err;
		}
	}

	err = camera_common_parse_clocks(dev, pdata);
	if (err)
		dev_warn(dev, "%s: camera_common_parse_clocks failed err=%d\n",
			 __func__, err);

	pw->mclk = devm_clk_get(dev, pdata->mclk_name ?: OV5647_DEFAULT_MCLK);
	if (IS_ERR(pw->mclk)) {
		err = PTR_ERR(pw->mclk);
		dev_err(dev, "%s: mclk get failed err=%d\n", __func__, err);
		pw->mclk = NULL;
		return err;
	}

	if (gpio_is_valid((int)pw->reset_gpio)) {
		err = devm_gpio_request_one(dev, pw->reset_gpio,
					    GPIOF_OUT_INIT_LOW,
					    "ov5647-reset");
		if (err) {
			dev_err(dev, "%s: reset gpio request failed err=%d\n",
				__func__, err);
			return err;
		}
	}

	if (gpio_is_valid((int)pw->pwdn_gpio)) {
		err = devm_gpio_request_one(dev, pw->pwdn_gpio,
					    GPIOF_OUT_INIT_HIGH,
					    "ov5647-pwdn");
		if (err) {
			dev_err(dev, "%s: pwdn gpio request failed err=%d\n",
				__func__, err);
			return err;
		}
	}

	dev_info(dev, "%s: exit\n", __func__);

	return 0;
}

static int ov5647_power_on(struct camera_common_data *s_data)
{
	struct device *dev = s_data->dev;
	struct camera_common_power_rail *pw = s_data->power;
	int err;

	dev_info(dev, "%s: enter\n", __func__);

	if (!pw)
		return -EINVAL;

	if (pw->state) {
		dev_dbg(dev, "%s: already on\n", __func__);
		return 0;
	}

	if (pw->iovdd) {
		err = regulator_enable(pw->iovdd);
		if (err) {
			dev_err(dev, "%s: iovdd enable failed err=%d\n",
				__func__, err);
			return err;
		}
	}

	if (pw->dvdd) {
		err = regulator_enable(pw->dvdd);
		if (err) {
			dev_err(dev, "%s: dvdd enable failed err=%d\n",
				__func__, err);
			goto disable_iovdd;
		}
	}

	if (pw->avdd) {
		err = regulator_enable(pw->avdd);
		if (err) {
			dev_err(dev, "%s: avdd enable failed err=%d\n",
				__func__, err);
			goto disable_dvdd;
		}
	}

	err = camera_common_mclk_enable(s_data);
	if (err) {
		dev_err(dev, "%s: mclk enable failed err=%d\n", __func__, err);
		goto disable_avdd;
	}

	usleep_range(1000, 1500);

	if (gpio_is_valid((int)pw->pwdn_gpio))
		gpio_set_value(pw->pwdn_gpio, 1);

	if (gpio_is_valid((int)pw->reset_gpio)) {
		gpio_set_value(pw->reset_gpio, 0);
		usleep_range(1000, 1500);
		gpio_set_value(pw->reset_gpio, 1);
	}

	usleep_range(5000, 6000);

	err = ov5647_write_table(s_data, ov5647_sensor_oe_enable_regs);
	if (err) {
		dev_err(dev, "%s: sensor output-enable table failed err=%d\n",
			__func__, err);
		goto disable_mclk;
	}

	/*
	 * Upstream OV5647 forces stream-stop during power-on to put the CSI
	 * lanes into LP-11 before the first real stream start.
	 */
	err = ov5647_write_stream_stop_regs(s_data, false);
	if (err) {
		dev_err(dev, "%s: stream-stop LP-11 setup failed err=%d\n",
			__func__, err);
		goto disable_mclk;
	}
	dev_info(dev, "%s: stream-stop LP-11 setup complete\n", __func__);

	pw->state = true;

	dev_info(dev, "%s: exit success\n", __func__);
	return 0;

disable_mclk:
	camera_common_mclk_disable(s_data);
disable_avdd:
	if (pw->avdd)
		regulator_disable(pw->avdd);
disable_dvdd:
	if (pw->dvdd)
		regulator_disable(pw->dvdd);
disable_iovdd:
	if (pw->iovdd)
		regulator_disable(pw->iovdd);
	return err;
}

static int ov5647_power_off(struct camera_common_data *s_data)
{
	struct device *dev;
	struct camera_common_power_rail *pw;

	if (!s_data)
		return 0;

	dev = s_data->dev;
	pw = s_data->power;

	if (!dev) {
		pr_warn("%s: s_data->dev is NULL, skipping power-off\n",
			__func__);
		return 0;
	}

	dev_info(dev, "%s: enter\n", __func__);

	if (!pw) {
		dev_warn(dev, "%s: s_data->power is NULL, skipping\n", __func__);
		return 0;
	}

	if (!pw->state) {
		dev_dbg(dev, "%s: already off\n", __func__);
		return 0;
	}

	if (ov5647_write_table(s_data, ov5647_sensor_oe_disable_regs))
		dev_warn(dev, "%s: sensor output-disable table failed\n",
			 __func__);

	if (gpio_is_valid((int)pw->pwdn_gpio))
		gpio_set_value(pw->pwdn_gpio, 1);

	if (gpio_is_valid((int)pw->reset_gpio))
		gpio_set_value(pw->reset_gpio, 0);

	camera_common_mclk_disable(s_data);

	if (pw->avdd)
		regulator_disable(pw->avdd);
	if (pw->dvdd)
		regulator_disable(pw->dvdd);
	if (pw->iovdd)
		regulator_disable(pw->iovdd);

	pw->state = false;
	dev_info(dev, "%s: exit success\n", __func__);

	return 0;
}

static int ov5647_power_put(struct tegracam_device *tc_dev)
{
	struct camera_common_data *s_data = tc_dev->s_data;
	struct camera_common_power_rail *pw;

	if (!s_data || !s_data->power)
		return -EINVAL;

	pw = s_data->power;
	pw->mclk = NULL;
	pw->reset_gpio = OV5647_GPIO_NOT_PRESENT;
	pw->pwdn_gpio = OV5647_GPIO_NOT_PRESENT;

	dev_info(tc_dev->dev, "%s: power rail references cleared\n", __func__);
	return 0;
}

static int ov5647_set_group_hold(struct tegracam_device *tc_dev, bool val)
{
	dev_dbg(tc_dev->dev, "%s: group_hold=%d (stub)\n", __func__, val);
	return 0;
}

static int ov5647_set_gain(struct tegracam_device *tc_dev, s64 val)
{
	dev_dbg(tc_dev->dev, "%s: gain=%lld not applied yet\n",
		__func__, val);
	return 0;
}

static int ov5647_set_exposure(struct tegracam_device *tc_dev, s64 val)
{
	dev_dbg(tc_dev->dev, "%s: exposure=%lld not applied yet\n",
		__func__, val);
	return 0;
}

static int ov5647_set_frame_rate(struct tegracam_device *tc_dev, s64 val)
{
	dev_dbg(tc_dev->dev, "%s: frame_rate=%lld not applied yet\n",
		__func__, val);
	return 0;
}

static int ov5647_set_mode(struct tegracam_device *tc_dev)
{
	struct camera_common_data *s_data = tc_dev->s_data;
	struct ov5647 *priv = to_ov5647(tc_dev);
	int mode = s_data ? s_data->mode : -1;
	u8 vc_ctrl;
	int err;

	if (mode < 0 || mode >= ARRAY_SIZE(ov5647_modes)) {
		dev_err(tc_dev->dev, "%s: invalid mode index %d\n", __func__, mode);
		return -EINVAL;
	}

	if (!priv || !priv->board_setup_done) {
		dev_err(tc_dev->dev, "%s: board setup not complete\n", __func__);
		return -EIO;
	}

	dev_info(tc_dev->dev,
		 "%s: applying mode=%d name=%s %ux%u\n",
		 __func__, mode, ov5647_modes[mode].name,
		 ov5647_modes[mode].width, ov5647_modes[mode].height);

	err = ov5647_write_table(s_data, ov5647_common_regs);
	if (err) {
		dev_err(tc_dev->dev, "%s: common table failed err=%d\n",
			__func__, err);
		return err;
	}

	err = ov5647_write_table(s_data, ov5647_modes[mode].table);
	if (err) {
		dev_err(tc_dev->dev, "%s: mode table failed err=%d\n",
			__func__, err);
		return err;
	}

	err = ov5647_read_reg(s_data, OV5647_REG_MIPI_CTRL14, &vc_ctrl);
	if (err)
		return err;

	vc_ctrl &= ~(3 << 6);
	err = ov5647_write_reg(s_data, OV5647_REG_MIPI_CTRL14, vc_ctrl);
	if (err)
		return err;

	dev_info(tc_dev->dev, "%s: mode applied, sensor remains in standby\n",
		 __func__);
	return 0;
}

static int ov5647_start_streaming(struct tegracam_device *tc_dev)
{
	struct camera_common_data *s_data = tc_dev->s_data;
	u8 val = OV5647_MIPI_CTRL00_BUS_IDLE |
		 OV5647_MIPI_CTRL00_CLOCK_LANE_GATE |
		 OV5647_MIPI_CTRL00_LINE_SYNC_ENABLE;
	int err;

	dev_info(tc_dev->dev, "%s: enter\n", __func__);

	err = ov5647_set_mode(tc_dev);
	if (err) {
		dev_err(tc_dev->dev, "%s: set_mode failed err=%d\n",
			__func__, err);
		return err;
	}

	err = ov5647_write_reg(s_data, OV5647_REG_MIPI_CTRL00, val);
	if (err)
		return err;

	err = ov5647_write_reg(s_data, OV5647_REG_FRAME_OFF_NUMBER, 0x00);
	if (err)
		return err;

	err = ov5647_write_reg(s_data, OV5647_REG_MODE_SELECT,
			       OV5647_MODE_STREAMING);
	if (err)
		return err;

	err = ov5647_write_reg(s_data, OV5640_REG_PAD_OUT, 0x00);
	if (err)
		return err;

	dev_info(tc_dev->dev, "%s: exit success\n", __func__);
	return 0;
}

static int ov5647_stop_streaming(struct tegracam_device *tc_dev)
{
	struct camera_common_data *s_data = tc_dev->s_data;
	int err;

	dev_info(tc_dev->dev, "%s: enter\n", __func__);

	err = ov5647_write_stream_stop_regs(s_data, true);
	if (err)
		return err;

	dev_info(tc_dev->dev, "%s: exit success\n", __func__);
	return 0;
}

static int ov5647_board_setup(struct ov5647 *priv)
{
	struct camera_common_data *s_data = priv->s_data;
	struct device *dev = s_data->dev;
	u8 chip_id_high = 0;
	u8 chip_id_low = 0;
	int err;

	dev_info(dev, "%s: enter\n", __func__);

	err = ov5647_power_on(s_data);
	if (err) {
		dev_err(dev, "%s: power_on failed err=%d\n", __func__, err);
		return err;
	}

	err = ov5647_read_reg(s_data, OV5647_REG_CHIP_ID_HIGH, &chip_id_high);
	if (err)
		goto power_off;

	err = ov5647_read_reg(s_data, OV5647_REG_CHIP_ID_LOW, &chip_id_low);
	if (err)
		goto power_off;

	priv->chip_id = (chip_id_high << 8) | chip_id_low;
	dev_info(dev, "%s: detected chip_id=0x%04x\n", __func__, priv->chip_id);

	if (priv->chip_id != OV5647_CHIP_ID) {
		dev_err(dev,
			"%s: unexpected chip_id=0x%04x expected=0x%04x\n",
			__func__, priv->chip_id, OV5647_CHIP_ID);
		err = -ENODEV;
		goto power_off;
	}

	priv->board_setup_done = true;
	err = 0;

power_off:
	if (ov5647_power_off(s_data))
		dev_warn(dev, "%s: power_off failed during unwind\n", __func__);

	if (err)
		dev_err(dev, "%s: exit failure err=%d\n", __func__, err);
	else
		dev_info(dev, "%s: exit success\n", __func__);

	return err;
}

static const struct tegracam_ctrl_ops ov5647_ctrl_ops = {
	.numctrls = ARRAY_SIZE(ov5647_ctrl_cid_list),
	.ctrl_cid_list = ov5647_ctrl_cid_list,
	.set_gain = ov5647_set_gain,
	.set_exposure = ov5647_set_exposure,
	.set_frame_rate = ov5647_set_frame_rate,
	.set_group_hold = ov5647_set_group_hold,
};

static struct camera_common_sensor_ops ov5647_common_ops = {
	.numfrmfmts = ARRAY_SIZE(ov5647_frmfmt),
	.frmfmt_table = ov5647_frmfmt,
	.power_on = ov5647_power_on,
	.power_off = ov5647_power_off,
	.write_reg = ov5647_write_reg,
	.read_reg = ov5647_read_reg,
	.parse_dt = ov5647_parse_dt,
	.power_get = ov5647_power_get,
	.power_put = ov5647_power_put,
	.set_mode = ov5647_set_mode,
	.start_streaming = ov5647_start_streaming,
	.stop_streaming = ov5647_stop_streaming,
};

static const struct v4l2_subdev_ops ov5647_subdev_ops = {
};

static int ov5647_probe(struct i2c_client *client,
			const struct i2c_device_id *id)
{
	struct device *dev = &client->dev;
	struct tegracam_device *tc_dev;
	struct ov5647 *priv;
	int err;

	dev_info(dev, "%s: enter client=%s addr=0x%02x\n",
		 __func__, client->name, client->addr);

	if (!allow_hw_probe) {
		dev_warn(dev,
			 "%s: probe gate is closed; reload with allow_hw_probe=1 after hardware mapping is verified\n",
			 __func__);
		return -EPERM;
	}

	if (!dev->of_node) {
		dev_err(dev, "%s: DT node is required\n", __func__);
		return -ENODEV;
	}

	tc_dev = devm_kzalloc(dev, sizeof(*tc_dev), GFP_KERNEL);
	if (!tc_dev)
		return -ENOMEM;

	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	mutex_init(&priv->lock);
	priv->client = client;

	strscpy(tc_dev->name, OV5647_NAME, sizeof(tc_dev->name));
	tc_dev->dev = dev;
	tc_dev->client = client;
	tc_dev->sensor_ops = &ov5647_common_ops;
	tc_dev->tcctrl_ops = &ov5647_ctrl_ops;
	tc_dev->v4l2sd_ops = &ov5647_subdev_ops;
	tc_dev->dev_regmap_config = &ov5647_regmap_config;
	tc_dev->numctrls = ARRAY_SIZE(ov5647_ctrl_cid_list);
	tc_dev->ctrl_cid_list = ov5647_ctrl_cid_list;
	tc_dev->version = tegracam_version(2, 0, 0);
	tc_dev->priv = priv;

	i2c_set_clientdata(client, tc_dev);
	priv->tc_dev = tc_dev;

	err = tegracam_device_register(tc_dev);
	if (err) {
		dev_err(dev, "%s: tegracam_device_register failed err=%d\n",
			__func__, err);
		return err;
	}

	priv->s_data = tc_dev->s_data;
	if (!priv->s_data) {
		dev_err(dev, "%s: tc_dev->s_data is NULL\n", __func__);
		err = -EINVAL;
		goto unregister_device;
	}

	tegracam_set_privdata(tc_dev, priv);
	dev_info(dev,
		 "%s: private data linked tc_dev=%p tc_dev->priv=%p s_data=%p s_data->priv=%p\n",
		 __func__, tc_dev, tc_dev->priv, priv->s_data,
		 priv->s_data->priv);

	if (!sensor_common_parse_num_modes(dev))
		dev_warn(dev, "%s: sensor_common_parse_num_modes returned 0\n",
			 __func__);

	err = sensor_common_init_sensor_properties(dev, dev->of_node,
						   &priv->s_data->sensor_props);
	if (err) {
		dev_err(dev,
			"%s: sensor_common_init_sensor_properties failed err=%d\n",
			__func__, err);
		goto unregister_device;
	}

	err = camera_common_parse_ports(dev, priv->s_data);
	if (err) {
		dev_err(dev, "%s: camera_common_parse_ports failed err=%d\n",
			__func__, err);
		goto unregister_device;
	}

	err = ov5647_board_setup(priv);
	if (err) {
		dev_err(dev, "%s: board setup failed err=%d\n", __func__, err);
		goto unregister_device;
	}

	if (skip_v4l2_register) {
		dev_info(dev,
			 "%s: skip_v4l2_register=1; leaving probe before v4l2 subdev registration\n",
			 __func__);
		dev_info(dev, "%s: exit success without v4l2 registration\n",
			 __func__);
		return 0;
	}

	err = tegracam_v4l2subdev_register(tc_dev, true);
	if (err) {
		dev_err(dev, "%s: tegracam_v4l2subdev_register failed err=%d\n",
			__func__, err);
		goto unregister_device;
	}
	priv->v4l2_registered = true;
	tegracam_set_privdata(tc_dev, priv);
	dev_info(dev,
		 "%s: v4l2 registered tc_dev=%p tc_dev->priv=%p s_data=%p s_data->priv=%p v4l2_registered=%d\n",
		 __func__, tc_dev, tc_dev->priv, priv->s_data,
		 priv->s_data->priv, priv->v4l2_registered);

	dev_info(dev, "%s: exit success\n", __func__);
	return 0;

unregister_device:
	tegracam_device_unregister(tc_dev);
	return err;
}

static int ov5647_remove(struct i2c_client *client)
{
	struct camera_common_data *s_data = to_camera_common_data(&client->dev);
	struct tegracam_device *tc_dev;
	struct ov5647 *priv;
	bool should_unregister_v4l2;

	dev_info(&client->dev, "%s: enter\n", __func__);

	if (!s_data) {
		dev_err(&client->dev,
			"%s: camera common data is NULL; refusing unsafe remove\n",
			__func__);
		return -EINVAL;
	}

	priv = s_data->priv;
	if (!priv || !priv->tc_dev) {
		dev_err(&client->dev,
			"%s: private data is invalid s_data=%p priv=%p; refusing unsafe remove\n",
			__func__, s_data, priv);
		return -EINVAL;
	}

	tc_dev = priv->tc_dev;
	should_unregister_v4l2 = !skip_v4l2_register;

	dev_info(&client->dev,
		 "%s: state tc_dev=%p tc_dev->dev=%p priv=%p tc_dev->priv=%p s_data=%p s_data->priv=%p v4l2_registered=%d skip_v4l2_register=%d skip_v4l2_unregister=%d split_v4l2_unregister=%d\n",
		 __func__, tc_dev, tc_dev->dev, priv, tc_dev->priv, s_data,
		 s_data ? s_data->priv : NULL,
		 priv ? priv->v4l2_registered : -1,
		 skip_v4l2_register, skip_v4l2_unregister,
		 split_v4l2_unregister);

	if (should_unregister_v4l2 && (!priv || !priv->v4l2_registered))
		dev_warn(&client->dev,
			 "%s: V4L2 registration flag is not set, but full probe path requires unregister; forcing V4L2 unregister before device cleanup\n",
			 __func__);

	if (should_unregister_v4l2) {
		dev_info(&client->dev,
			 "%s: before tegracam_v4l2subdev_unregister\n",
			 __func__);
		ov5647_unload_marker_delay();
		if (skip_v4l2_unregister) {
			dev_warn(&client->dev,
				 "%s: skip_v4l2_unregister=1; diagnostic leak risk, skipping v4l2 unregister\n",
				 __func__);
		} else if (split_v4l2_unregister) {
			dev_warn(&client->dev,
				 "%s: split_v4l2_unregister=1; diagnostic path, using inline unregister phases\n",
				 __func__);
			ov5647_split_v4l2subdev_unregister(tc_dev);
			if (priv)
				priv->v4l2_registered = false;
		} else {
			tegracam_v4l2subdev_unregister(tc_dev);
			if (priv)
				priv->v4l2_registered = false;
		}
		dev_info(&client->dev,
			 "%s: after tegracam_v4l2subdev_unregister\n",
			 __func__);
	} else {
		dev_info(&client->dev,
			 "%s: skipping v4l2 unregister s_data=%p skip_v4l2_register=%d\n",
			 __func__, s_data, skip_v4l2_register);
	}

	dev_info(&client->dev, "%s: before tegracam_device_unregister\n",
		 __func__);
	ov5647_unload_marker_delay();
	tegracam_device_unregister(tc_dev);
	dev_info(&client->dev, "%s: after tegracam_device_unregister\n",
		 __func__);

	if (priv)
		mutex_destroy(&priv->lock);

	dev_info(&client->dev, "%s: exit success\n", __func__);
	return 0;
}

static const struct of_device_id ov5647_of_match[] = {
	{ .compatible = "ovti,ov5647" },
	{ },
};
MODULE_DEVICE_TABLE(of, ov5647_of_match);

static const struct i2c_device_id ov5647_i2c_id[] = {
	{ "ov5647", 0 },
	{ },
};
MODULE_DEVICE_TABLE(i2c, ov5647_i2c_id);

static struct i2c_driver ov5647_i2c_driver = {
	.driver = {
		.name = OV5647_NAME,
		.of_match_table = ov5647_of_match,
	},
	.probe = ov5647_probe,
	.remove = ov5647_remove,
	.id_table = ov5647_i2c_id,
};

static int __init nv_ov5647_init(void)
{
	int err = 0;

	pr_info("%s: module init register_i2c_driver=%d allow_hw_probe=%d skip_v4l2_register=%d skip_v4l2_unregister=%d split_v4l2_unregister=%d unload_marker_delay_ms=%u\n",
		OV5647_NAME, register_i2c_driver, allow_hw_probe,
		skip_v4l2_register, skip_v4l2_unregister, split_v4l2_unregister,
		unload_marker_delay_ms);

	if (!register_i2c_driver) {
		pr_info("%s: safety gate active; i2c driver registration skipped\n",
			OV5647_NAME);
		return 0;
	}

	err = i2c_add_driver(&ov5647_i2c_driver);
	if (err) {
		pr_err("%s: i2c_add_driver failed err=%d\n", OV5647_NAME, err);
		return err;
	}

	driver_registered = true;
	pr_info("%s: i2c driver registered\n", OV5647_NAME);

	return 0;
}

static void __exit nv_ov5647_exit(void)
{
	pr_info("%s: module exit enter driver_registered=%d\n",
		OV5647_NAME, driver_registered);
	ov5647_unload_marker_delay();

	if (driver_registered) {
		pr_info("%s: before i2c_del_driver\n", OV5647_NAME);
		ov5647_unload_marker_delay();
		i2c_del_driver(&ov5647_i2c_driver);
		pr_info("%s: after i2c_del_driver\n", OV5647_NAME);
		driver_registered = false;
		pr_info("%s: i2c driver unregistered\n", OV5647_NAME);
		return;
	}

	pr_info("%s: module exit without i2c driver registration\n", OV5647_NAME);
}

module_init(nv_ov5647_init);
module_exit(nv_ov5647_exit);

MODULE_AUTHOR("OpenAI Codex");
MODULE_DESCRIPTION("OV5647 Jetson bring-up scaffold for Jetson Linux r36.5");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("0.1.0");
