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
public class FarmerProductService {

    public List<Product> findMyProducts(String farmerId,
                                        String kw,
                                        String categoryId,
                                        BigDecimal min,
                                        BigDecimal max,
                                        String sort,
                                        Integer page,
                                        Integer size) {

        if (farmerId == null || farmerId.isBlank()) return List.of();

        StringBuilder sql = new StringBuilder("""
            SELECT productId, productname, description, price, availability, categoryId,
                   farmerId, stock, img, status
            FROM product
            WHERE farmerId = ?
        """);

        List<Object> params = new ArrayList<>();
        params.add(farmerId);

        if (kw != null && !kw.trim().isEmpty()) {
            sql.append(" AND (LOWER(productname) LIKE ? OR LOWER(description) LIKE ?) ");
            String like = "%" + kw.trim().toLowerCase() + "%";
            params.add(like); params.add(like);
        }
        if (categoryId != null && !categoryId.trim().isEmpty()) {
            sql.append(" AND categoryId = ? "); params.add(categoryId.trim());
        }
        if (min != null) { sql.append(" AND price >= ? "); params.add(min); }
        if (max != null) { sql.append(" AND price <= ? "); params.add(max); }

        String orderBy = switch (safe(sort)) {
            case "price_asc"  -> "price ASC, productname ASC";
            case "price_desc" -> "price DESC, productname ASC";
            case "name_asc"   -> "productname ASC";
            case "name_desc"  -> "productname DESC";
            default           -> "productId DESC";
        };
        sql.append(" ORDER BY ").append(orderBy);

        int s = (size == null || size < 1) ? 12 : Math.min(size, 200);
        int p = (page == null || page < 1) ? 1 : page;
        int offset = (p - 1) * s;
        sql.append(" LIMIT ? OFFSET ? ");
        params.add(s); params.add(offset);

        try (Session ses = HibernateConnection.getSessionFactory().openSession()) {
            return ses.doReturningWork(conn -> {
                List<Product> list = new ArrayList<>();
                try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                    int i = 1;
                    for (Object o : params) {
                        if (o instanceof BigDecimal bd) ps.setBigDecimal(i++, bd);
                        else if (o instanceof Integer n) ps.setInt(i++, n);
                        else ps.setString(i++, String.valueOf(o));
                    }
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            Product pr = new Product();
                            pr.setProductId(rs.getString("productId"));
                            pr.setProductname(rs.getString("productname"));
                            pr.setDescription(rs.getString("description"));
                            pr.setPrice(rs.getBigDecimal("price"));

                            Object av = rs.getObject("availability");
                            if (av != null) {
                                String v = String.valueOf(av);
                                boolean ok = "1".equals(v) || "true".equalsIgnoreCase(v);
                                pr.setAvailability(ok);
                            }

                            pr.setCategoryId(rs.getString("categoryId"));
                            pr.setFarmerId(rs.getString("farmerId"));
                            pr.setStock(rs.getInt("stock"));
                            pr.setImg(rs.getString("img"));
                            pr.setStatus(rs.getString("status"));
                            list.add(pr);
                        }
                    }
                } catch (SQLException e) {
                    throw new RuntimeException("โหลดสินค้าของฉันล้มเหลว: " + e.getMessage(), e);
                }
                return list;
            });
        }
    }

    private static String safe(String s){ return s==null? "" : s.trim().toLowerCase(); }
}
