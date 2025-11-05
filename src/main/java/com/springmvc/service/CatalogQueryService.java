package com.springmvc.service;

import com.springmvc.model.HibernateConnection;
import com.springmvc.model.Product;
import org.hibernate.Session;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Service
public class CatalogQueryService {

    public List<Product> searchPublicProducts(
            String kw, String categoryId, BigDecimal minPrice, BigDecimal maxPrice,
            String sort, int page, int size) {

        StringBuilder sql = new StringBuilder(
            "SELECT productId, productname, description, price, " +
            "       stock, categoryId, farmerId, img, status " +
            "FROM product WHERE 1=1 "
        );
        List<Object> params = new ArrayList<>();

        if (kw != null && !kw.trim().isEmpty()) {
            sql.append("AND (productname LIKE ? OR description LIKE ?) ");
            String pat = "%" + kw.trim() + "%";
            params.add(pat); params.add(pat);
        }
        if (categoryId != null && !categoryId.trim().isEmpty()) {
            sql.append("AND categoryId = ? "); params.add(categoryId.trim());
        }
        if (minPrice != null) { sql.append("AND price >= ? "); params.add(minPrice); }
        if (maxPrice != null) { sql.append("AND price <= ? "); params.add(maxPrice); }

        String orderBy = switch (safe(sort)) {
            case "price_asc"  -> "price ASC, productname ASC";
            case "price_desc" -> "price DESC, productname ASC";
            case "name_asc"   -> "productname ASC";
            case "name_desc"  -> "productname DESC";
            default           -> "productId DESC";
        };
        sql.append("ORDER BY ").append(orderBy).append(' ');

        int safeSize = size <= 0 ? 24 : Math.min(size, 200);
        int safePage = page <= 0 ? 1 : page;
        int offset = (safePage - 1) * safeSize;
        sql.append("LIMIT ? OFFSET ? ");
        params.add(safeSize);
        params.add(offset);

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.doReturningWork(conn -> {
                List<Product> list = new ArrayList<>();
                try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                    int i = 1;
                    for (Object p : params) {
                        if (p instanceof BigDecimal bd) ps.setBigDecimal(i++, bd);
                        else if (p instanceof Integer in) ps.setInt(i++, in);
                        else ps.setString(i++, String.valueOf(p));
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Product p = new Product();
                            p.setProductId(rs.getString("productId"));
                            p.setProductname(rs.getString("productname"));
                            p.setDescription(rs.getString("description"));
                            p.setPrice(rs.getBigDecimal("price"));
                            p.setStock(rs.getInt("stock"));
                            p.setCategoryId(rs.getString("categoryId"));
                            p.setFarmerId(rs.getString("farmerId"));
                            p.setImg(rs.getString("img"));
                            try { p.setStatus(rs.getString("status")); } catch (Exception ignore) {}
                            list.add(p);
                        }
                    }
                } catch (SQLException e) {
                    throw new RuntimeException("ค้นหาสินค้าสาธารณะล้มเหลว: " + e.getMessage(), e);
                }
                return list;
            });
        }
    }

    private static String safe(String s){ return (s == null ? "" : s.trim().toLowerCase()); }
}
