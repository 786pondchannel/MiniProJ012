package com.springmvc.controller;

import com.springmvc.model.Category;
import com.springmvc.model.HibernateConnection;
import com.springmvc.model.Product;
import jakarta.servlet.http.HttpServletRequest;
import org.hibernate.Session;
import org.hibernate.query.Query;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Controller
public class MainController {

    @GetMapping({"/", "/main"})
    public String main(Model model, HttpServletRequest req) {
        List<Product>  products   = getLatestProducts(12);
        List<Category> categories = getAllCategories();
        List<String>   heroImages = defaultHeroImages(req.getContextPath());

        model.addAttribute("products", products);
        model.addAttribute("categories", categories);
        model.addAttribute("heroImages", heroImages);
        return "main"; // => /WEB-INF/jsp/main.jsp
    }

    private List<Product> getLatestProducts(int limit) {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Query<Product> q = s.createQuery(
                    "from Product p order by p.productId desc", Product.class);
            q.setMaxResults(Math.max(1, limit));
            List<Product> list = q.list();
            return list != null ? list : Collections.emptyList();
        } catch (Exception e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    private List<Category> getAllCategories() {
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            List<Category> list = s.createQuery(
                    "from Category c order by c.categoryId asc", Category.class).list();
            return list != null ? list : Collections.emptyList();
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private List<String> defaultHeroImages(String ctx) {
        List<String> imgs = new ArrayList<>();
        imgs.add(ctx + "/assets/01.jpg");
        imgs.add(ctx + "/assets/02.jpeg");
        imgs.add(ctx + "/assets/03.jpg");
        imgs.add(ctx + "/assets/04.jpg");
        return imgs;
    }
}
