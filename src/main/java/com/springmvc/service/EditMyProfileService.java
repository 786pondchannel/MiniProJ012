package com.springmvc.service;

import com.springmvc.model.ConnectionDB;
import com.springmvc.model.Member;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.sql.*;
import java.util.Objects;
import java.util.UUID;

@Service
public class EditMyProfileService {

    // ===== ให้สอดคล้องกับ WebConfig: ใช้ env UPLOAD_DIR ถ้าไม่มีก็ default (Win -> D:/Toos/png/ , อื่น ๆ -> /app/uploads/)
    private static final String OS = System.getProperty("os.name", "").toLowerCase();
    private static final String DEFAULT_ROOT = OS.contains("win") ? "D:/Toos/png/" : "/app/uploads/";
    private static final String UPLOAD_ROOT = ensureTrailingSlash(System.getenv().getOrDefault("UPLOAD_DIR", DEFAULT_ROOT));
    private static final String UPLOAD_URL_PREFIX = "/uploads/"; // URL ที่ฝั่งเว็บต้องเห็นเสมอ

    private static final long MAX_SIZE = 5L * 1024 * 1024; // 5MB

    private static String ensureTrailingSlash(String p) {
        if (p == null || p.isEmpty()) return "/";
        return (p.endsWith("/") || p.endsWith("\\")) ? p : (p + "/");
    }

    /** อ่านโปรไฟล์จาก DB */
    public Member getCurrentProfile(String memberId) {
        Member m = null;
        String sql = """
            SELECT `memberId`, `Fullname`, `PhoneNumber`, `email`, `Address`, `password`, `imageUrl`, `status`
              FROM `member`
             WHERE `memberId` = ?
        """;
        try (Connection conn = new ConnectionDB().getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, memberId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    m = new Member();
                    m.setMemberId(rs.getString("memberId"));
                    m.setFullname(rs.getString("Fullname"));
                    m.setPhoneNumber(rs.getString("PhoneNumber"));
                    m.setEmail(rs.getString("email"));
                    m.setAddress(rs.getString("Address"));
                    m.setPassword(rs.getString("password"));
                    m.setImageUrl(rs.getString("imageUrl"));
                    m.setStatus(rs.getString("status"));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error fetching profile for member " + memberId
                    + " | SQLState=" + e.getSQLState() + ", code=" + e.getErrorCode() + ", msg=" + e.getMessage(), e);
        }
        return m;
    }

    /** อัปเดตโปรไฟล์ + อัปโหลดรูป (ถ้ามีเลือกไฟล์) */
    public void updateProfile(Member incoming, MultipartFile imageFile) {
        // อ่านค่าเดิม
        Member current = getCurrentProfile(incoming.getMemberId());
        if (current == null) {
            throw new RuntimeException("No member found: " + incoming.getMemberId());
        }

        // เซฟรูปใหม่ถ้ามี
        String imageUrl = current.getImageUrl();
        if (imageFile != null && !imageFile.isEmpty()) {
            validateImage(imageFile);
            // ลบไฟล์เก่าถ้าชี้ใต้ /uploads/
            deleteOldIfLocal(imageUrl);
            // เซฟใหม่ลงโฟลเดอร์จริง (UPLOAD_ROOT) แล้วคืน URL /uploads/...
            imageUrl = saveProfileImage(incoming.getMemberId(), imageFile);
        }

        // Merge ฟิลด์อื่น
        String fullname    = pick(incoming.getFullname(),    current.getFullname());
        String phoneNumber = pick(incoming.getPhoneNumber(), current.getPhoneNumber());
        String email       = pick(incoming.getEmail(),       current.getEmail());
        String address     = pick(incoming.getAddress(),     current.getAddress());
        String password    = pick(incoming.getPassword(),    current.getPassword()); // โปรดใช้ hash จริงในโปรดักชัน

        String sql = """
            UPDATE `member`
               SET `Fullname`    = ?,
                   `PhoneNumber` = ?,
                   `email`       = ?,
                   `Address`     = ?,
                   `password`    = ?,
                   `imageUrl`    = ?
             WHERE `memberId`    = ?
        """;

        try (Connection conn = new ConnectionDB().getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, fullname);
            ps.setString(2, phoneNumber);
            ps.setString(3, email);
            ps.setString(4, address);
            ps.setString(5, password);
            ps.setString(6, imageUrl);
            ps.setString(7, incoming.getMemberId());

            int rows = ps.executeUpdate();
            if (rows == 0) throw new RuntimeException("No row updated for member " + incoming.getMemberId());

        } catch (SQLException e) {
            String detail = "SQLState=" + e.getSQLState() + ", code=" + e.getErrorCode() + ", msg=" + e.getMessage();
            throw new RuntimeException("Error updating profile for member " + incoming.getMemberId() + " | " + detail, e);
        }
    }

    /** เซฟไฟล์จริงแล้วคืน URL สำหรับเว็บ (เช่น /uploads/profile/{memberId}/{uuid}.jpg) */
    private String saveProfileImage(String memberId, MultipartFile file) {
        String safeMemberId = (memberId == null ? "user" : memberId.replaceAll("[^A-Za-z0-9_-]", "_"));

        Path root = Paths.get(UPLOAD_ROOT).toAbsolutePath().normalize();
        Path userDir = root.resolve(Paths.get("profile", safeMemberId)).normalize();

        // สร้างโฟลเดอร์
        try {
            Files.createDirectories(userDir);
        } catch (IOException e) {
            throw new RuntimeException("Cannot create upload dir: " + userDir.toAbsolutePath(), e);
        }

        String ext = guessExtension(file.getOriginalFilename());
        String newName = UUID.randomUUID().toString().replace("-", "") + "." + ext.toLowerCase();
        Path dest = userDir.resolve(newName).normalize();

        // กัน path หลุด root
        if (!dest.toAbsolutePath().startsWith(root.toAbsolutePath())) {
            throw new RuntimeException("Invalid upload path");
        }

        try (InputStream in = file.getInputStream()) {
            Files.copy(in, dest, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Cannot save upload file to " + dest.toAbsolutePath(), e);
        }

        // คืน URL ที่ให้ WebConfig เสิร์ฟได้
        return UPLOAD_URL_PREFIX + "profile/" + safeMemberId + "/" + newName;
    }

    /** ลบรูปเก่า (ถ้าชี้ใน /uploads/ เท่านั้น) */
    private void deleteOldIfLocal(String oldUrl) {
        if (oldUrl == null) return;
        String url = oldUrl.trim();
        if (url.isEmpty()) return;
        // ข้ามกรณีเป็นลิงก์ http(s)
        if (url.startsWith("http://") || url.startsWith("https://")) return;
        if (!url.startsWith(UPLOAD_URL_PREFIX)) return;

        Path root = Paths.get(UPLOAD_ROOT).toAbsolutePath().normalize();

        // map /uploads/... -> {UPLOAD_ROOT}/...
        String sep = FileSystems.getDefault().getSeparator();
        String relative = url.substring(UPLOAD_URL_PREFIX.length()).replace("/", sep);
        Path target = root.resolve(relative).normalize();

        try {
            if (Files.isRegularFile(target)) {
                Files.deleteIfExists(target);
            }
        } catch (IOException ignored) { /* ลบไม่ได้ก็ข้าม */ }
    }

    /** ตรวจชนิด/ขนาดไฟล์แบบเบาๆ */
    private void validateImage(MultipartFile f) {
        String ct = f.getContentType();
        boolean okType = ct != null && (
                Objects.equals(ct, "image/jpeg") ||
                Objects.equals(ct, "image/png")  ||
                Objects.equals(ct, "image/webp")
        );
        if (!okType) throw new RuntimeException("อัปโหลดได้เฉพาะไฟล์ .jpg .png .webp");
        if (f.getSize() > MAX_SIZE) throw new RuntimeException("ไฟล์รูปต้องไม่เกิน 5MB");
    }

    private String guessExtension(String originalName) {
        if (originalName == null) return "jpg";
        String lower = originalName.toLowerCase();
        if (lower.endsWith(".png"))  return "png";
        if (lower.endsWith(".webp")) return "webp";
        if (lower.endsWith(".jpg"))  return "jpg";
        if (lower.endsWith(".jpeg")) return "jpg";
        return "jpg";
    }

    private String pick(String incoming, String fallback) {
        return (incoming == null || incoming.trim().isEmpty()) ? fallback : incoming.trim();
    }
}
