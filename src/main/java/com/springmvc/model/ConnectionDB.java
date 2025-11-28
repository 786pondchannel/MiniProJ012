package com.springmvc.model;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConnectionDB {

    // อ่านค่าจาก ENV; ถ้าไม่มีให้ใช้ default (สะดวกเวลารันนอก Docker)
    private static final String DB_HOST     = getEnv("DB_HOST", "localhost");
    private static final String DB_PORT     = getEnv("DB_PORT", "3307");           // นอก Docker แนะนำ map เป็น 3307/3308
    private static final String DB_NAME     = getEnv("DB_NAME", "preorder_farm");
    private static final String DB_USER     = getEnv("DB_USER", "root");
    private static final String DB_PASSWORD = getEnv("DB_PASSWORD", "1234");

    // พารามิเตอร์ที่ช่วยเรื่อง Unicode/Timezone/SSL/MySQL8
    private static final String PARAMS = "?useUnicode=true"
            + "&characterEncoding=UTF-8"
            + "&serverTimezone=Asia/Bangkok"
            + "&useSSL=false"
            + "&allowPublicKeyRetrieval=true";

    private static String getEnv(String key, String def) {
        String v = System.getenv(key);
        return (v == null || v.isEmpty()) ? def : v;
    }

    public static Connection getConnection() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url = String.format("jdbc:mysql://%s:%s/%s%s", DB_HOST, DB_PORT, DB_NAME, PARAMS);
            return DriverManager.getConnection(url, DB_USER, DB_PASSWORD);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("MySQL JDBC Driver not found", e);
        } catch (SQLException e) {
            throw new RuntimeException("Cannot connect to database", e);
        }
    }
}
