package com.hyp.common;

public final class Constants {

    private Constants() {}

    public static final String ROLE_ELDER = "ELDER";
    public static final String ROLE_GUARDIAN = "GUARDIAN";

    public static final String ALERT_YELLOW = "YELLOW";
    public static final String ALERT_ORANGE = "ORANGE";
    public static final String ALERT_RED = "RED";

    public static final String RISK_HEART_RATE = "HEART_RATE";
    public static final String RISK_SPO2 = "SPO2";
    public static final String RISK_FALL = "FALL";
    public static final String RISK_INACTIVITY = "INACTIVITY";
    public static final String RISK_SLEEP = "SLEEP";

    public static final String CHANNEL_PUSH = "PUSH";
    public static final String CHANNEL_SMS = "SMS";
    public static final String CHANNEL_EMAIL = "EMAIL";

    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_SENT = "SENT";
    public static final String STATUS_FAILED = "FAILED";
    public static final String STATUS_DELAYED = "DELAYED";
    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_INACTIVE = "INACTIVE";

    public static final int MERGE_WINDOW_SECONDS = 300;
    public static final int MAX_ALERT_RETRIES = 3;
}
