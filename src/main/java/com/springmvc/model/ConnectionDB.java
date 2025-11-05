package com.springmvc.model;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConnectionDB {

    private static final String HOST      = "jdbc:mysql://localhost:3307/";
    private static final String DB_NAME   = "preorder_farm";   // ✅ ใช้ชื่อนี้ให้ตรงกันทั้งโปรเจค
    private static final String PARAMS    =
        "?useUnicode=true&characterEncoding=UTF-8" +
        "&serverTimezone=Asia/Bangkok" +
        "&useSSL=false" +
        "&allowPublicKeyRetrieval=true";
    private static final String URL       = HOST + DB_NAME + PARAMS;

    private static final String USERNAME  = "root";
    private static final String PASSWORD  = "1234";

    public Connection getConnection() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            // ✅ สร้าง DB ถ้ายังไม่มี
            try (Connection c = DriverManager.getConnection(HOST + PARAMS, USERNAME, PASSWORD)) {
                try (java.sql.Statement st = c.createStatement()) {
                    st.executeUpdate(
                        "CREATE DATABASE IF NOT EXISTS " + DB_NAME +
                        " DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                    );
                }
            } catch (SQLException e) {
                e.printStackTrace(); // log ไว้ แต่ไม่ทำให้แอปล้ม
            }

            return DriverManager.getConnection(URL, USERNAME, PASSWORD);
        } catch (ClassNotFoundException | SQLException ex) {
            ex.printStackTrace();
            throw new RuntimeException("Cannot connect to database", ex);
        }
    }
}
