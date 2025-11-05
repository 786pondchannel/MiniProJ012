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

                
                props.put("hibernate.connection.driver_class", "com.mysql.cj.jdbc.Driver");
                props.put("hibernate.connection.url",
                    "jdbc:mysql://localhost:3307/preorder_farm"
                    + "?useUnicode=true&characterEncoding=UTF-8"
                    + "&serverTimezone=Asia/Bangkok"
                    + "&useSSL=false"
                    + "&allowPublicKeyRetrieval=true"
                );
                props.put("hibernate.connection.username", "root");
                props.put("hibernate.connection.password", "1234");

                
                props.put("hibernate.dialect", "org.hibernate.dialect.MySQLDialect");

                // ให้ Hibernate สร้าง/อัปเดต schema ให้อัตโนมัติ 
                props.put("hibernate.hbm2ddl.auto", "update");

                // ดีบัก (เปิดเมื่ออยากดู SQL)
                // props.put("hibernate.show_sql", "true");
                // props.put("hibernate.format_sql", "true");

                // สำหรับกรณี lazy load ใน view (เปิดถ้าจำเป็น)
                // props.put("hibernate.enable_lazy_load_no_trans", "true");

                StandardServiceRegistry registry = new StandardServiceRegistryBuilder()
                        .applySettings(props)
                        .build();

                MetadataSources sources = new MetadataSources(registry)
                        // ===== เอนทิตีให้ =====
                        .addAnnotatedClass(com.springmvc.model.Member.class)
                        .addAnnotatedClass(com.springmvc.model.Farmer.class)
                        .addAnnotatedClass(com.springmvc.model.Category.class)
                        .addAnnotatedClass(com.springmvc.model.Product.class)
                        .addAnnotatedClass(com.springmvc.model.ProductImage.class)
                        .addAnnotatedClass(com.springmvc.model.FarmerImage.class)
                        .addAnnotatedClass(com.springmvc.model.Review.class)
                        
                        .addAnnotatedClass(com.springmvc.model.Perorder.class)       
                        .addAnnotatedClass(com.springmvc.model.PreorderDetail.class)  
                        .addAnnotatedClass(com.springmvc.model.Receipt.class);        

                Metadata metadata = sources.getMetadataBuilder().build();

                // ❌ ไม่ต้องมีโค้ด SQL สร้างตารางเองแล้ว ปล่อยให้ hbm2ddl ทำงาน

                sessionFactory = metadata.buildSessionFactory();

            } catch (Exception ex) {
                ex.printStackTrace();
                throw new RuntimeException("Could not build SessionFactory", ex);
            }
        }
        return sessionFactory;
    }
}
