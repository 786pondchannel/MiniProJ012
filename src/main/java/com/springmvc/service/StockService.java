package com.springmvc.service;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ตัด/คืนสต๊อก “กิโลกรัม” แบบอะตอมมิก
 * - auto-resolve ชื่อตาราง/คอลัมน์จาก DB metadata (หรือบังคับผ่าน VM/ENV)
 *   -Ddb.table.products=product
 *   -Ddb.column.stock=stock
 *   -Ddb.column.productId=productId
 *   -Ddb.user=root  -Ddb.pass=1234
 *   ENV: DB_TABLE_PRODUCTS / DB_COLUMN_STOCK / DB_COLUMN_PRODUCTID / DB_USER / DB_PASS
 */
@Service
public class StockService {

    // ---------- DB URLs (พอร์ต 3307 มาก่อน) ----------
    private static final List<String> URLS = Arrays.asList(
        "jdbc:mysql://127.0.0.1:3307/preorder_farm?useSSL=false&sslMode=DISABLED&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8&connectTimeout=5000&socketTimeout=60000",
        "jdbc:mariadb://127.0.0.1:3307/preorder_farm?useUnicode=true&characterEncoding=UTF-8&connectTimeout=5000&socketTimeout=60000",
        "jdbc:mysql://127.0.0.1:3306/preorder_farm?useSSL=false&sslMode=DISABLED&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8&connectTimeout=5000&socketTimeout=60000",
        "jdbc:mariadb://127.0.0.1:3306/preorder_farm?useUnicode=true&characterEncoding=UTF-8&connectTimeout=5000&socketTimeout=60000",
        "jdbc:mysql://localhost:3307/preorder_farm?useSSL=false&sslMode=DISABLED&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8&connectTimeout=5000&socketTimeout=60000",
        "jdbc:mariadb://localhost:3307/preorder_farm?useUnicode=true&characterEncoding=UTF-8&connectTimeout=5000&socketTimeout=60000"
    );

    private volatile boolean resolved = false;
    private String tableName;     // เช่น product / products
    private String idColumn;      // เช่น productId / product_id / id
    private String stockColumn;   // เช่น stock / stock / qty

    /* ===================== PUBLIC APIs (int เดิม) ===================== */

    /** ลดแบบ “ชิ้น” เดิม (ยังคงไว้เพื่อ backward compatibility) */
    public boolean decreaseStockAtomic(String productId, int qty) {
        if (qty <= 0) return true;
        try (Connection c = getConn()) {
            ensureResolved(c);
            final String sql =
                "UPDATE " + tableName +
                " SET " + stockColumn + " = COALESCE(" + stockColumn + ",0) - ? " +
                " WHERE " + idColumn + " = ? AND COALESCE(" + stockColumn + ",0) >= ?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setInt(1, qty);
                ps.setString(2, productId);
                ps.setInt(3, qty);
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("ลดสต๊อก (ชิ้น) ล้มเหลว: " + e.getMessage(), e);
        }
    }

    /** เพิ่มแบบ “ชิ้น” เดิม */
    public void increaseStock(String productId, int qty) {
        if (qty <= 0) return;
        try (Connection c = getConn()) {
            ensureResolved(c);
            final String sql =
                "UPDATE " + tableName +
                " SET " + stockColumn + " = COALESCE(" + stockColumn + ",0) + ? " +
                " WHERE " + idColumn + " = ?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setInt(1, qty);
                ps.setString(2, productId);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("คืนสต๊อก (ชิ้น) ล้มเหลว: " + e.getMessage(), e);
        }
    }

    /* ===================== NEW: APIs แบบ “กิโลกรัม” ===================== */

    /** ลดสต๊อก (กิโลกรัม) – ใช้คอนเนกชันภายนอก (เช่นจาก Hibernate tx) */
    public boolean decreaseStockKg(Connection c, String productId, BigDecimal kg) throws SQLException {
        if (kg == null || kg.signum() <= 0) return true;
        kg = kg.setScale(3, RoundingMode.HALF_UP);

        ensureResolved(c);
        final String v = "CAST(COALESCE(" + stockColumn + ",0) AS DECIMAL(18,3))";
        final String sql =
            "UPDATE " + tableName +
            " SET " + stockColumn + " = ROUND(" + v + " - ?, 3) " +
            " WHERE " + idColumn + " = ? AND " + v + " >= ?";

        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBigDecimal(1, kg);
            ps.setString(2, productId);
            ps.setBigDecimal(3, kg);
            return ps.executeUpdate() > 0;
        }
    }

    /** ลดสต๊อก (กิโลกรัม) – เปิดคอนเนกชันเอง (ไม่ผูกกับ tx ภายนอก) */
    public boolean decreaseStockKg(String productId, BigDecimal kg) {
        if (kg == null || kg.signum() <= 0) return true;
        kg = kg.setScale(3, RoundingMode.HALF_UP);
        try (Connection c = getConn()) {
            return decreaseStockKg(c, productId, kg);
        } catch (SQLException e) {
            throw new RuntimeException("ลดสต๊อก (กก.) ล้มเหลว: " + e.getMessage(), e);
        }
    }

    /** เพิ่มสต๊อก (กิโลกรัม) – ใช้คอนเนกชันภายนอก */
    public void increaseStockKg(Connection c, String productId, BigDecimal kg) throws SQLException {
        if (kg == null || kg.signum() <= 0) return;
        kg = kg.setScale(3, RoundingMode.HALF_UP);

        ensureResolved(c);
        final String v = "CAST(COALESCE(" + stockColumn + ",0) AS DECIMAL(18,3))";
        final String sql =
            "UPDATE " + tableName +
            " SET " + stockColumn + " = ROUND(" + v + " + ?, 3) " +
            " WHERE " + idColumn + " = ?";

        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setBigDecimal(1, kg);
            ps.setString(2, productId);
            ps.executeUpdate();
        }
    }

    /** เพิ่มสต๊อก (กิโลกรัม) – เปิดคอนเนกชันเอง */
    public void increaseStockKg(String productId, BigDecimal kg) {
        if (kg == null || kg.signum() <= 0) return;
        kg = kg.setScale(3, RoundingMode.HALF_UP);
        try (Connection c = getConn()) {
            increaseStockKg(c, productId, kg);
        } catch (SQLException e) {
            throw new RuntimeException("คืนสต๊อก (กก.) ล้มเหลว: " + e.getMessage(), e);
        }
    }

    /* ===================== schema resolver ===================== */

    private synchronized void ensureResolved(Connection c) throws SQLException {
        if (resolved) return;

        // 1) บังคับชื่อผ่าน ENV/PROP ได้
        String forcedTable = firstNonEmpty(env("DB_TABLE_PRODUCTS"), prop("db.table.products"));
        String forcedStock = firstNonEmpty(env("DB_COLUMN_STOCK"),  prop("db.column.stock"));
        String forcedId    = firstNonEmpty(env("DB_COLUMN_PRODUCTID"), prop("db.column.productId"));

        if (forcedTable != null && forcedStock != null && forcedId != null) {
            this.tableName   = forcedTable;
            this.stockColumn = forcedStock;
            this.idColumn    = forcedId;
            this.resolved    = true;
            return;
        }

        // 2) เดาจาก metadata
        DatabaseMetaData md = c.getMetaData();
        List<String> allTables = readTables(md);
        List<String> productTables = allTables.stream()
                .filter(t -> t.toLowerCase(Locale.ROOT).contains("product"))
                .collect(Collectors.toList());
        if (productTables.isEmpty()) {
            throw new RuntimeException("ไม่พบตารางที่มีคำว่า 'product' เลยในสคีมา: " + allTables);
        }

        for (String t : productTables) {
            Map<String, Integer> cols = readColumns(md, t);

            // id
            String idCol = pickFirst(cols.keySet(), Arrays.asList(
                "productid", "product_id", t + "_id", "id", "productId", "PRODUCT_ID", "ProductID"
            ));

            // stock numeric
            List<String> stockCandidates = Arrays.asList(
                "stockquantity", "stock_quantity", "stockqty", "stock", "qty", "quantity",
                "StockQuantity", "STOCK_QTY", "stock"
            );
            String stockCol = pickFirstNumeric(cols, stockCandidates);

            if (idCol != null && stockCol != null) {
                this.tableName   = t;
                this.idColumn    = idCol;
                this.stockColumn = stockCol;
                this.resolved    = true;
                return;
            }
        }

        StringBuilder sb = new StringBuilder("หา schema ไม่ได้: ตรวจเจอตาราง ")
                .append(productTables)
                .append(" แต่ไม่มีคอลัมน์ id/stock ที่เข้าเงื่อนไข\n");
        for (String t : productTables) {
            sb.append("  - ").append(t).append(" : ").append(readColumns(md, t).keySet()).append("\n");
        }
        throw new RuntimeException(sb.toString());
    }

    /* ===================== helpers ===================== */

    private Connection getConn() throws SQLException {
        String user = firstNonEmpty(env("DB_USER"), prop("db.user"), "root");
        String pass = firstNonEmpty(env("DB_PASS"), prop("db.pass"), "1234");
        SQLException last = null;
        for (String url : URLS) {
            try { return DriverManager.getConnection(url, user, pass); }
            catch (SQLException ex) { last = ex; }
        }
        throw last != null ? last : new SQLException("เชื่อมต่อฐานข้อมูลไม่ได้ (ไม่มี URL ใช้งานได้)");
    }

    private static String env(String k){ return System.getenv(k); }
    private static String prop(String k){ return System.getProperty(k); }

    private static String firstNonEmpty(String... v) {
        for (String s : v) if (s != null && !s.trim().isEmpty()) return s.trim();
        return null;
    }

    private static List<String> readTables(DatabaseMetaData md) throws SQLException {
        List<String> out = new ArrayList<>();
        try (ResultSet rs = md.getTables(null, null, "%", new String[]{"TABLE","VIEW"})) {
            while (rs.next()) out.add(rs.getString("TABLE_NAME"));
        }
        return out;
    }

    private static Map<String, Integer> readColumns(DatabaseMetaData md, String table) throws SQLException {
        Map<String, Integer> cols = new LinkedHashMap<>();
        try (ResultSet rs = md.getColumns(null, null, table, "%")) {
            while (rs.next()) {
                cols.put(rs.getString("COLUMN_NAME"), rs.getInt("DATA_TYPE"));
            }
        }
        return cols;
    }

    private static String pickFirst(Set<String> pool, List<String> preferences) {
        Set<String> lower = pool.stream().map(s->s.toLowerCase(Locale.ROOT)).collect(Collectors.toSet());
        for (String pref : preferences) {
            if (lower.contains(pref.toLowerCase(Locale.ROOT))) {
                for (String s : pool) if (s.equalsIgnoreCase(pref)) return s;
            }
        }
        for (String s : pool) {
            String ls = s.toLowerCase(Locale.ROOT);
            if (ls.equals("productid") || ls.equals("product_id") || ls.equals("id")) return s;
        }
        return null;
    }

    private static String pickFirstNumeric(Map<String,Integer> cols, List<String> preferences) {
        for (String pref : preferences) {
            String col = findCaseInsensitive(cols.keySet(), pref);
            if (col != null && isNumeric(cols.get(col))) return col;
        }
        for (String name : cols.keySet()) {
            String l = name.toLowerCase(Locale.ROOT);
            if ((l.contains("stock") || l.contains("qty") || l.contains("quantity")) && isNumeric(cols.get(name))) {
                return name;
            }
        }
        return null;
    }

    private static String findCaseInsensitive(Set<String> pool, String want) {
        for (String s : pool) if (s.equalsIgnoreCase(want)) return s;
        return null;
    }

    private static boolean isNumeric(Integer jdbcType) {
        if (jdbcType == null) return false;
        switch (jdbcType) {
            case Types.INTEGER:
            case Types.BIGINT:
            case Types.SMALLINT:
            case Types.TINYINT:
            case Types.DECIMAL:
            case Types.NUMERIC:
            case Types.FLOAT:
            case Types.REAL:
            case Types.DOUBLE:
                return true;
            default:
                return false;
        }
    }
}
