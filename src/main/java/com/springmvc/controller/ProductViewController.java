package com.springmvc.controller;

import com.springmvc.model.Product;
import com.springmvc.model.ConnectionDB;
import com.springmvc.service.ProductService;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.sql.*;
import java.util.*;

@Controller
@RequestMapping("/product")
public class ProductViewController {

    @Autowired private ProductService productService;

    @GetMapping("/view/{id}")
    public String view(@PathVariable("id") String id, HttpSession session, Model model) {

        Product p = productService.getProduct(id);
        if (p == null) { model.addAttribute("error","ไม่พบสินค้าที่ต้องการ"); return "redirect:/product/list"; }
        model.addAttribute("product", p);

        List<ImageRow> images = safeLoadImages(p.getProductId());
        if (images.isEmpty() && notBlank(p.getImg())) {
            images = new ArrayList<>(); images.add(new ImageRow(p.getImg()));
        }
        model.addAttribute("images", images);

        String categoryName = safeLoadCategoryName(p.getCategoryId());
        String farmerName   = safeLoadFarmerName(p.getFarmerId());
        if (notBlank(categoryName)) model.addAttribute("categoryName", categoryName);
        if (notBlank(farmerName))   model.addAttribute("farmerName", farmerName);

        List<RelatedRow> related = safeLoadRelated(p.getCategoryId(), p.getProductId(), 8);
        model.addAttribute("relatedProducts", related);

        return "ViewProduct";
    }

    public static class ImageRow {
        private String imageUrl;
        public ImageRow() {}
        public ImageRow(String imageUrl) { this.imageUrl = imageUrl; }
        public String getImageUrl() { return imageUrl; }
        public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    }

    public static class RelatedRow {
        private String productId;
        private String productname;
        private String img;
        private BigDecimal price;
        public String getProductId() { return productId; }
        public void setProductId(String productId) { this.productId = productId; }
        public String getProductname() { return productname; }
        public void setProductname(String productname) { this.productname = productname; }
        public String getImg() { return img; }
        public void setImg(String img) { this.img = img; }
        public BigDecimal getPrice() { return price; }
        public void setPrice(BigDecimal price) { this.price = price; }
    }

    private List<ImageRow> safeLoadImages(String productId) {
        if (!notBlank(productId)) return Collections.emptyList();
        String sql = """
            SELECT imageUrl
              FROM product_image
             WHERE productId = ?
             ORDER BY sortOrder ASC, imageId ASC
        """;
        try (Connection c = new ConnectionDB().getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, productId);
            List<ImageRow> list = new ArrayList<>();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String url = rs.getString("imageUrl");
                    if (notBlank(url)) list.add(new ImageRow(url));
                }
            }
            return list;
        } catch (SQLException e) {
            System.err.println("[ProductView] load images error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    private String safeLoadCategoryName(String categoryId) {
        if (!notBlank(categoryId)) return null;
        String sql = "SELECT name FROM category WHERE categoryId = ?";
        try (Connection c = new ConnectionDB().getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, categoryId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("name");
            }
        } catch (SQLException e) { System.err.println("[ProductView] load category error: " + e.getMessage()); }
        return null;
    }

    private String safeLoadFarmerName(String farmerId) {
        if (!notBlank(farmerId)) return null;
        String sql = "SELECT farmName FROM farmer WHERE farmerId = ?";
        try (Connection c = new ConnectionDB().getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, farmerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("farmName");
            }
        } catch (SQLException e) { System.err.println("[ProductView] load farmer error: " + e.getMessage()); }
        return null;
    }

    private List<RelatedRow> safeLoadRelated(String categoryId, String excludeProductId, int limit) {
        if (!notBlank(categoryId)) return Collections.emptyList();
        String sql = """
            SELECT p.productId, p.productname AS productname, p.img AS img, p.price
              FROM product p
             WHERE p.categoryId = ?
               AND p.productId <> ?
             ORDER BY p.productId DESC
             LIMIT ?
        """;
        try (Connection c = new ConnectionDB().getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, categoryId);
            ps.setString(2, Objects.toString(excludeProductId, ""));
            ps.setInt(3, Math.max(1, limit));
            List<RelatedRow> list = new ArrayList<>();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RelatedRow r = new RelatedRow();
                    r.setProductId(rs.getString("productId"));
                    r.setProductname(rs.getString("productname"));
                    r.setImg(rs.getString("img"));
                    r.setPrice(rs.getBigDecimal("price"));
                    list.add(r);
                }
            }
            return list;
        } catch (SQLException e) {
            System.err.println("[ProductView] load related error: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    private boolean notBlank(String s) { return s != null && !s.trim().isEmpty(); }
}
