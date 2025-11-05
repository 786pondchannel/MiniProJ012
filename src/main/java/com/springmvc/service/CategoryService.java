package com.springmvc.service;

import com.springmvc.model.Category;
import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class CategoryService {
    private final SessionFactory sf = HibernateConnection.getSessionFactory();

    public List<Category> getAllCategories() {
        try (Session session = sf.openSession()) {
            return session.createQuery("from Category", Category.class).list();
        }
    }
}
