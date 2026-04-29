# 2026-04-29 Physical CSI Guide Expansion

## Goal

Expand the existing physical CSI validation document into a field-ready bench
guide for the current OV5647 no-SOF investigation.

## Updated Document

- `docs/12-physical-csi-validation.md`

## What Was Added

- a bench-oriented physical validation workflow;
- a live-use pin reference table;
- an interpretation matrix for common measurement outcomes;
- a recommended equipment section split by budget/value tier;
- a tool-usage table describing what each instrument is useful for in this
  repository;
- a concrete command trigger sequence for physical measurement sessions.

## Why This Change Matters

The repository has already established a strong software-side negative result:

- `I2C` works;
- `VIDIOC_STREAMON` succeeds;
- sensor-side stream state remains active;
- Jetson receiver clocks come up;
- but `SOF/NVCSI/VI` ingress is still absent.

That makes physical CSI validation the highest-value next debugging branch.

## Practical Outcome

The updated document can now be used directly at the bench to:

- inspect cable orientation and contact side;
- check power and low-speed signals;
- confirm presence or absence of `MCLK`;
- probe for CSI lane activity during a controlled stream attempt;
- map observed measurements to the next engineering action.
