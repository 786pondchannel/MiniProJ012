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

/**
 * เสิร์ฟไฟล์รูปสำหรับการชำระเงิน (QR ร้าน / สลิปออเดอร์)
 * รองรับทั้งเส้นทางจากตาราง receipt.Img และ perorder.receipt_path
 *
 * โครงสร้างไฟล์ที่รองรับ:
 *   - สลิปอัปโหลด: D:/Toos/png/receipts/{uuid}.{png|jpg|jpeg|webp}   (receipt.Img เก็บ "receipts/{uuid}.ext")
 *   - QR ร้าน:     D:/Toos/png/slip/{farmerId}/qr.png (หรือไฟล์รูปใดๆ ในโฟลเดอร์นั้น)
 *   - Fallback:    D:/Toos/png/slip/{farmerId}/{orderId}.*  (กรณีเก่าที่ตั้งชื่อตาม orderId)
 */
@Controller
@RequestMapping("/payment")
public class PaymentAssetController {

    // โฟลเดอร์หลัก
    private static final Path SLIP_BASE     = Paths.get("D:/Toos/png/slip");      // สำหรับ QR และ fallback เดิม
    private static final Path RECEIPTS_DIR  = Paths.get("D:/Toos/png/receipts");  // สำหรับสลิปที่ผู้ซื้ออัปโหลดจริง

    /* =============================== Endpoints =============================== */

    /** GET /payment/qr/{farmerId} : รูป QR ของร้าน */
    @GetMapping("/qr/{farmerId}")
    public void getFarmerQr(@PathVariable String farmerId, HttpServletResponse resp) throws IOException {
        Path dir = safe(SLIP_BASE.resolve(sanitizeId(farmerId)));
        if (!Files.isDirectory(dir)) { notFound(resp, "QR dir not found"); return; }

        Optional<Path> f = pickBestImageInDir(dir, List.of("qr", "promptpay", "payment"));
        if (f.isEmpty()) f = newestImage(dir);
        if (f.isEmpty()) { notFound(resp, "QR image not found"); return; }

        streamFile(resp, f.get(), true, 300);
    }

    /**
     * GET /payment/receipt/{orderId} : รูปสลิปล่าสุดของออเดอร์
     * ลำดับความสำคัญ:
     *   1) ตาราง receipt (ล่าสุด) -> RECEIPTS_DIR
     *   2) perorder.receipt_path (http/https → redirect, path → stream)
     *   3) Fallback: SLIP_BASE/{farmerId}/{orderId}.*
     */
    @GetMapping("/receipt/{orderId}")
    public void getOrderReceipt(@PathVariable String orderId, HttpServletResponse resp) throws IOException {
        String farmerId = null;
        String receiptPathCol = null;

        // ดึง farmerId + (อาจจะ) receipt_path จาก perorder
        try (Session s = HibernateConnection.getSessionFactory().openSession()) {

            boolean hasReceiptPath = hasReceiptPathColumn(s);

            // 1) เช็คสลิปล่าสุดจากตาราง receipt ก่อนเลย (วิธีหลักของคุณตอนอัปโหลด)
            @SuppressWarnings("unchecked")
            List<Object[]> r1 = (List<Object[]>) s.createNativeQuery("""
                SELECT Img
                  FROM receipt
                 WHERE perorder_orderId = :oid
                 ORDER BY receiptId DESC
                 LIMIT 1
            """).setParameter("oid", orderId).list();

            if (r1 != null && !r1.isEmpty() && r1.get(0)[0] != null) {
                String img = String.valueOf(r1.get(0)[0]).trim(); // เช่น "receipts/uuid.jpg" หรือ "/uploads/receipts/..."
                Path p = resolveReceiptImgPath(img);
                if (p != null && Files.isRegularFile(p)) {
                    // ไม่แคช เพื่อให้เห็นไฟล์ล่าสุดทันที
                    streamFileNoCache(resp, p);
                    return;
                }
                // ถ้ามีค่าใน DB แต่ไฟล์หาย → ไปขั้นต่อไป
            }

            // 2) อ่าน farmerId + perorder.receipt_path (ถ้ามี)
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

        // 2.1) ถ้ามี perorder.receipt_path → ใช้ก่อน
        if (receiptPathCol != null && !receiptPathCol.isBlank()) {
            String low = receiptPathCol.toLowerCase(Locale.ROOT);
            if (low.startsWith("http://") || low.startsWith("https://")) {
                // รูปออนไลน์ → redirect
                resp.setStatus(302);
                resp.setHeader("Location", receiptPathCol);
                return;
            }
            Path p = resolveReceiptImgPath(receiptPathCol);
            if (p == null) {
                // รองรับกรณีให้ path แปลกๆ → ลองมอง relative จาก SLIP_BASE เผื่อ
                p = safe(SLIP_BASE.resolve(receiptPathCol.replace("\\","/")));
            }
            if (p != null && Files.isRegularFile(p)) {
                streamFileNoCache(resp, p);
                return;
            }
            // ถ้ามีค่าแต่ไฟล์ไม่อยู่ → ไป fallback ข้อ 3
        }

        // 3) Fallback เดิม: หาใน SLIP_BASE/{farmerId}/{orderId}.*
        if (farmerId == null || farmerId.isBlank()) { notFound(resp, "farmerId missing"); return; }
        Path dir = safe(SLIP_BASE.resolve(sanitizeId(farmerId)));
        if (!Files.isDirectory(dir)) { notFound(resp, "dir not found"); return; }

        Optional<Path> byPrefix = newestByPrefix(dir, orderId);
        if (byPrefix.isPresent()) {
            streamFileNoCache(resp, byPrefix.get());
            return;
        }

        notFound(resp, "receipt not found");
    }

    /* =============================== Helpers =============================== */

    /** กัน path traversal และ normalize ให้ชัวร์ว่าภายใต้ไดเรคทอรีที่คาดหวัง */
    private Path safe(Path candidate) throws IOException {
        Path norm = candidate.normalize().toAbsolutePath();
        Path slip = SLIP_BASE.normalize().toAbsolutePath();
        Path recp = RECEIPTS_DIR.normalize().toAbsolutePath();
        if (!norm.startsWith(slip) && !norm.startsWith(recp)) {
            throw new IOException("Blocked path outside allowed base");
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

    /** map ค่า Img จาก DB → ไฟล์จริงในดิสก์ (รองรับทั้ง relative หลายรูปแบบ และ absolute) */
    private Path resolveReceiptImgPath(String img) throws IOException {
        if (img == null || img.isBlank()) return null;
        String clean = img.replace("\\","/");

        // absolute path
        Path p = Paths.get(clean);
        if (p.isAbsolute()) return safe(p);

        // relative: รองรับหลายรูปแบบที่พบบ่อย
        if (clean.startsWith("uploads/receipts/")) clean = clean.substring("uploads/receipts/".length());
        else if (clean.startsWith("/uploads/receipts/")) clean = clean.substring("/uploads/receipts/".length());
        else if (clean.startsWith("receipts/")) clean = clean.substring("receipts/".length());
        else if (clean.startsWith("/receipts/")) clean = clean.substring("/receipts/".length());

        return safe(RECEIPTS_DIR.resolve(clean));
    }

    /** เลือกไฟล์รูปที่ชื่อมีคีย์เวิร์ด (เช่น qr/promptpay) ถ้ามีหลายไฟล์ เลือกใหม่สุด */
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

    /** เอารูปใหม่สุดในโฟลเดอร์ */
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

    /** หาไฟล์ที่ชื่อขึ้นต้นด้วย {prefix}.* (และเป็นรูป) ใหม่สุด */
    private Optional<Path> newestByPrefix(Path dir, String prefix) throws IOException {
        String preLow = (prefix == null ? "" : prefix.toLowerCase(Locale.ROOT));
        if (!Files.isDirectory(dir)) return Optional.empty();
        return Files.list(dir)
                .filter(Files::isRegularFile)
                .filter(this::isImage)
                .filter(p -> p.getFileName().toString().toLowerCase(Locale.ROOT).startsWith(preLow))
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

    /** stream แบบไม่แคช (ให้หน้าเว็บเห็นอัปเดตทันที) */
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
            if (n.endsWith(".png"))      ct = "image/png";
            else if (n.endsWith(".jpg") || n.endsWith(".jpeg")) ct = "image/jpeg";
            else if (n.endsWith(".webp")) ct = "image/webp";
            else if (n.endsWith(".gif"))  ct = "image/gif";
            else                          ct = "application/octet-stream";
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

    /* =============================== DB helpers =============================== */

    /** ตรวจว่าตาราง perorder มีคอลัมน์ receipt_path หรือไม่ */
    private boolean hasReceiptPathColumn(Session s) {
        try {
            @SuppressWarnings("unchecked")
            List<Object[]> rows = (List<Object[]>) s.createNativeQuery("SHOW COLUMNS FROM perorder LIKE 'receipt_path'").list();
            return rows != null && !rows.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }
}
