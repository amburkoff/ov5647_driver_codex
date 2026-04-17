#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>

#define NV_OV5647_MODULE_NAME "nv_ov5647"

static int __init nv_ov5647_init(void)
{
	pr_info("%s: skeleton module loaded; hardware probing is intentionally disabled\n",
		NV_OV5647_MODULE_NAME);
	return 0;
}

static void __exit nv_ov5647_exit(void)
{
	pr_info("%s: skeleton module unloaded\n", NV_OV5647_MODULE_NAME);
}

module_init(nv_ov5647_init);
module_exit(nv_ov5647_exit);

MODULE_AUTHOR("OpenAI Codex");
MODULE_DESCRIPTION("OV5647 Jetson bring-up skeleton module for Jetson Linux r36.5");
MODULE_LICENSE("GPL v2");
MODULE_VERSION("0.0.1");

