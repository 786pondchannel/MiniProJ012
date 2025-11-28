package com.springmvc.model;

import java.util.Properties;
import org.hibernate.SessionFactory;
import org.hibernate.boot.Metadata;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistry;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;

public class HibernateConnection {
    private static SessionFactory sessionFactory;

    public static SessionFactory getSessionFactory() {
        if (sessionFactory == null) {
            try {
                Properties props = new Properties();

                // ===== JDBC/MySQL =====
                props.put("hibernate.connection.driver_class", "com.mysql.cj.jdbc.Driver");
                props.put("hibernate.connection.url",
                    "jdbc:mysql://mysql:3306/preorder_farm"
                    + "?useUnicode=true&characterEncoding=UTF-8"
                    + "&serverTimezone=Asia/Bangkok"
                    + "&useSSL=false"
                    + "&allowPublicKeyRetrieval=true"
                );
                props.put("hibernate.connection.username", "root");   // ใช้ค่าเดิมของคุณ
                props.put("hibernate.connection.password", "1234");   // ใช้ค่าเดิมของคุณ

                // ===== Hibernate 6 Dialect =====
                props.put("hibernate.dialect", "org.hibernate.dialect.MySQLDialect");

                // ให้ hibernate ช่วย sync โครงสร้าง (ตามแบบที่คุณใช้เดิม)
                props.put("hibernate.hbm2ddl.auto", "update");

                // ดีบัก SQL (เปิดเมื่อจำเป็น)
                // props.put("hibernate.show_sql", "true");
                // props.put("hibernate.format_sql", "true");

                StandardServiceRegistry registry = new StandardServiceRegistryBuilder()
                        .applySettings(props)
                        .build();

                // ======= ลงทะเบียนเอนทิตีที่โปรเจ็กต์นี้ใช้ =======
                MetadataSources sources = new MetadataSources(registry)
                        .addAnnotatedClass(com.springmvc.model.Member.class)
                        .addAnnotatedClass(com.springmvc.model.Farmer.class)
                        .addAnnotatedClass(com.springmvc.model.Category.class)
                        .addAnnotatedClass(com.springmvc.model.Product.class)       // << สำคัญ
                        .addAnnotatedClass(com.springmvc.model.ProductImage.class) // << สำคัญ
                        .addAnnotatedClass(com.springmvc.model.FarmerImage.class)
                        .addAnnotatedClass(com.springmvc.model.Review.class)
                        .addAnnotatedClass(com.springmvc.model.Perorder.class)
                        .addAnnotatedClass(com.springmvc.model.PreorderDetail.class)
                        .addAnnotatedClass(com.springmvc.model.Receipt.class);

                Metadata metadata = sources.getMetadataBuilder().build();
                sessionFactory = metadata.buildSessionFactory();

            } catch (Exception ex) {
                ex.printStackTrace();
                throw new RuntimeException("Could not build SessionFactory", ex);
            }
        }
        return sessionFactory;
    }
}
