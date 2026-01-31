package com.springmvc.controller;

import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/payment")
public class PaymentAssetController {

    /* ===================== โฟลเดอร์หลัก (อิง UPLOAD_DIR หรือ auto-detect) ===================== */
    private static Path uploadRoot() {
        // 1) ถ้าตั้ง env ไว้ ให้ใช้ก่อน
        String env = System.getenv("UPLOAD_DIR");
        if (env != null && !env.isBlank()) {
            Path p = Paths.get(env).toAbsolutePath().normalize();
            if (Files.isDirectory(p)) return p;
        }

        // 2) auto-detect: ไล่หาโฟลเดอร์ "uploads" จาก user.dir (มักเป็น base ของ Tomcat/Eclipse)
        // พยายามขึ้นไป 0..8 ชั้น
        Path cur = Paths.get(System.getProperty("user.dir", ".")).toAbsolutePath().normalize();
        for (int i = 0; i <= 8; i++) {
            Path candidate = cur.resolve("uploads").normalize();
            if (Files.isDirectory(candidate)) return candidate;
            cur = cur.getParent();
            if (cur == null) break;
        }

        // 3) fallback เดิม (เผื่อ production)
        String os = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        String defaultPath = os.contains("win") ? "D:/Toos/png/" : "/app/uploads/";
        return Paths.get(defaultPath).toAbsolutePath().normalize();
    }

    private static final Path UPLOAD_ROOT  = uploadRoot();

    // ✅ โครงสร้างของคุณ: uploads/farmers/<farmerId>/slip
    private static final Path FARMERS_BASE = UPLOAD_ROOT.resolve("farmers").normalize();

    // สลิปผู้ซื้อ (คงเดิม เผื่อคุณใช้)
    private static final Path RECEIPTS_DIR = UPLOAD_ROOT.resolve("receipts").normalize();

    /* =============================== Endpoints =============================== */

    /** GET /payment/qr/{farmerId} : รูป QR ของร้าน */
    @GetMapping("/qr/{farmerId}")
    public void getFarmerQr(@PathVariable String farmerId, HttpServletResponse resp) throws IOException {
        String fid = sanitizeId(farmerId);

        // ✅ ตรงกับของคุณ: uploads/farmers/<fid>/slip
        Path dir = safe(FARMERS_BASE.resolve(fid).resolve("slip"));
        if (!Files.isDirectory(dir)) {
            notFound(resp, "QR dir not found: " + dir);
            return;
        }

        Optional<Path> f = pickBestImageInDir(dir, List.of("qr", "promptpay", "payment"));
        if (f.isEmpty()) f = newestImage(dir);
        if (f.isEmpty()) {
            notFound(resp, "QR image not found in: " + dir);
            return;
        }

        // QR เปลี่ยนไม่บ่อย: cache ได้เล็กน้อย
        streamFile(resp, f.get(), true, 300);
    }

    /**
     * GET /payment/receipt/{orderId} : รูปสลิปล่าสุดของออเดอร์
     * (ของเดิมคุณใช้ได้ต่อ – ถ้า path ฝั่ง DB ถูกต้อง)
     */
    @GetMapping("/receipt/{orderId}")
    public void getOrderReceipt(@PathVariable String orderId, HttpServletResponse resp) throws IOException {
        String farmerId = null;
        String receiptPathCol = null;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            boolean hasReceiptPath = hasReceiptPathColumn(s);

            @SuppressWarnings("unchecked")
            List<Object[]> r1 = (List<Object[]>) s.createNativeQuery("""
                SELECT Img
                  FROM receipt
                 WHERE perorder_orderId = :oid
                 ORDER BY receiptId DESC
                 LIMIT 1
            """).setParameter("oid", orderId).list();

            if (r1 != null && !r1.isEmpty() && r1.get(0)[0] != null) {
                String img = String.valueOf(r1.get(0)[0]).trim();
                Path p = resolveReceiptImgPath(img);
                if (p != null && Files.isRegularFile(p)) {
                    streamFileNoCache(resp, p);
                    return;
                }
            }

            String sql = hasReceiptPath
                    ? "SELECT farmerId, receipt_path FROM perorder WHERE orderId=:oid"
                    : "SELECT farmerId FROM perorder WHERE orderId=:oid";

            @SuppressWarnings("unchecked")
            List<Object[]> r2 = (List<Object[]>) s.createNativeQuery(sql)
                    .setParameter("oid", orderId)
                    .list();

            if (r2 == null || r2.isEmpty()) { notFound(resp, "order not found"); return; }

            Object[] row = r2.get(0);
            farmerId = String.valueOf(row[0]);

            if (hasReceiptPath && row.length > 1 && row[1] != null) {
                receiptPathCol = String.valueOf(row[1]).trim();
            }
        } catch (Exception ex) {
            notFound(resp, "order lookup error");
            return;
        }

        if (receiptPathCol != null && !receiptPathCol.isBlank()) {
            String low = receiptPathCol.toLowerCase(Locale.ROOT);
            if (low.startsWith("http://") || low.startsWith("https://")) {
                resp.setStatus(302);
                resp.setHeader("Location", receiptPathCol);
                return;
            }
            Path p = resolveReceiptImgPath(receiptPathCol);
            if (p != null && Files.isRegularFile(p)) {
                streamFileNoCache(resp, p);
                return;
            }
        }

        // fallback เดิม: ถ้าอยากให้เข้ากับโครงสร้าง uploads/farmers/<fid>/slip ก็ปรับได้อีก
        notFound(resp, "receipt not found");
    }

    /* =============================== Helpers =============================== */

    /** กัน path traversal และยืนยันว่าอยู่ใต้ UPLOAD_ROOT เท่านั้น */
    private Path safe(Path candidate) throws IOException {
        Path norm = candidate.normalize().toAbsolutePath();
        Path base = UPLOAD_ROOT.normalize().toAbsolutePath();
        if (!norm.startsWith(base)) {
            throw new IOException("Blocked path outside upload root: " + norm);
        }
        return norm;
    }

    /** กรอง id ให้เหลือ [a-zA-Z0-9-_] เท่านั้น */
    private String sanitizeId(String s) {
        if (s == null) return "";
        return s.replaceAll("[^a-zA-Z0-9_-]", "");
    }

    private boolean isImage(Path p) {
        String name = p.getFileName().toString().toLowerCase(Locale.ROOT);
        return name.endsWith(".png") || name.endsWith(".jpg") || name.endsWith(".jpeg")
                || name.endsWith(".webp") || name.endsWith(".gif");
    }

    private Path resolveReceiptImgPath(String img) throws IOException {
        if (img == null || img.isBlank()) return null;
        String clean = img.replace("\\","/");

        Path abs = Paths.get(clean);
        if (abs.isAbsolute()) return safe(abs);

        if (clean.startsWith("/")) clean = clean.substring(1);
        if (clean.startsWith("uploads/")) clean = clean.substring("uploads/".length());

        if (clean.startsWith("receipts/")) {
            return safe(RECEIPTS_DIR.resolve(clean.substring("receipts/".length())));
        }
        return safe(RECEIPTS_DIR.resolve(clean));
    }

    private Optional<Path> pickBestImageInDir(Path dir, List<String> keywords) throws IOException {
        if (!Files.isDirectory(dir)) return Optional.empty();
        List<Path> imgs = Files.list(dir)
                .filter(Files::isRegularFile)
                .filter(this::isImage)
                .collect(Collectors.toList());
        if (imgs.isEmpty()) return Optional.empty();

        Path best = null;
        long bestScore = Long.MIN_VALUE;
        for (Path p : imgs) {
            final String name = p.getFileName().toString().toLowerCase(Locale.ROOT);
            long score = 0;
            for (String k : keywords) if (name.contains(k)) score += 1000;
            try { score += Files.getLastModifiedTime(p).toMillis() / 1000; } catch (IOException ignore) {}
            if (score > bestScore) { bestScore = score; best = p; }
        }
        return Optional.ofNullable(best);
    }

    private Optional<Path> newestImage(Path dir) throws IOException {
        if (!Files.isDirectory(dir)) return Optional.empty();
        return Files.list(dir)
                .filter(Files::isRegularFile)
                .filter(this::isImage)
                .max(Comparator.comparingLong(p -> {
                    try { return Files.getLastModifiedTime(p).toMillis(); }
                    catch (IOException e) { return 0L; }
                }));
    }

    private void notFound(HttpServletResponse resp, String msg) throws IOException {
        resp.setStatus(404);
        resp.setContentType("text/plain; charset=UTF-8");
        resp.getWriter().write("404 Not Found: " + msg);
    }

    private void streamFileNoCache(HttpServletResponse resp, Path file) throws IOException {
        streamFile(resp, file, true, 0);
        resp.setHeader("Cache-Control","no-store, no-cache, must-revalidate, max-age=0");
        resp.setHeader("Pragma","no-cache");
    }

    private void streamFile(HttpServletResponse resp, Path file, boolean inline, int maxAgeSec) throws IOException {
        if (!Files.isRegularFile(file)) { notFound(resp, "file missing"); return; }

        String ct = Files.probeContentType(file);
        if (ct == null || !ct.startsWith("image/")) {
            String n = file.getFileName().toString().toLowerCase(Locale.ROOT);
            if      (n.endsWith(".png"))       ct = "image/png";
            else if (n.endsWith(".jpg") || n.endsWith(".jpeg")) ct = "image/jpeg";
            else if (n.endsWith(".webp"))      ct = "image/webp";
            else if (n.endsWith(".gif"))       ct = "image/gif";
            else                               ct = "application/octet-stream";
        }

        resp.setStatus(200);
        resp.setContentType(ct);
        resp.setHeader("Cache-Control", "public, max-age=" + Math.max(0, maxAgeSec));
        resp.setHeader("X-Accel-Buffering", "no");

        String disp = (inline ? "inline" : "attachment") + "; filename=\"" + file.getFileName().toString() + "\"";
        resp.setHeader("Content-Disposition", disp);

        try (InputStream in = Files.newInputStream(file, StandardOpenOption.READ)) {
            in.transferTo(resp.getOutputStream());
        }
        resp.flushBuffer();
    }

    private boolean hasReceiptPathColumn(Session s) {
        try {
            @SuppressWarnings("unchecked")
            List<Object[]> rows = (List<Object[]>) s.createNativeQuery(
                    "SHOW COLUMNS FROM perorder LIKE 'receipt_path'"
            ).list();
            return rows != null && !rows.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
}
