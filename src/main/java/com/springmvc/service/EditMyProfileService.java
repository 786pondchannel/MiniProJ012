package com.springmvc.service;

import com.springmvc.model.ConnectionDB;
import com.springmvc.model.Member;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.sql.*;
import java.util.UUID;

@Service
public class EditMyProfileService {

    // ต้องตรงกับ WebConfig.addResourceHandlers("/uploads/**" -> "file:///D:/Toos/png/")
    private static final String UPLOAD_DIR = "D:/Toos/png/";

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
        // อ่านค่าเดิม มาช่วย merge กัน NULL/ช่องว่าง
        Member current = getCurrentProfile(incoming.getMemberId());
        if (current == null) {
            throw new RuntimeException("No member found: " + incoming.getMemberId());
        }

        // รูป: ถ้ามีไฟล์ใหม่ → เซฟ แล้วตั้ง URL; ถ้าไม่ → ใช้ค่าเดิม
        String imageUrl = current.getImageUrl();
        if (imageFile != null && !imageFile.isEmpty()) {
            imageUrl = saveProfileImage(incoming.getMemberId(), imageFile); // ex: /uploads/profile/m001/xxx.jpg
        }

        // Merge ฟิลด์อื่น ๆ: ถ้าไม่ได้กรอก/เป็นค่าว่าง ให้ใช้ค่าเดิม
        String fullname    = pick(incoming.getFullname(),    current.getFullname());
        String phoneNumber = pick(incoming.getPhoneNumber(), current.getPhoneNumber());
        String email       = pick(incoming.getEmail(),       current.getEmail());
        String address     = pick(incoming.getAddress(),     current.getAddress());
        String password    = pick(incoming.getPassword(),    current.getPassword()); // (โปรดพิจารณา hash password จริงในโปรดักชัน)

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

            ps.executeUpdate();

        } catch (SQLException e) {
            String detail = "SQLState=" + e.getSQLState() + ", code=" + e.getErrorCode() + ", msg=" + e.getMessage();
            throw new RuntimeException("Error updating profile for member " + incoming.getMemberId() + " | " + detail, e);
        }
    }

    /** เซฟไฟล์จริงด้วย Files.copy (กัน cross-drive) แล้วคืน URL สำหรับเว็บ */
    private String saveProfileImage(String memberId, MultipartFile file) {
        String safeMemberId = (memberId == null ? "user" : memberId.replaceAll("[^A-Za-z0-9_-]", "_"));
        Path userDir = Paths.get(UPLOAD_DIR, "profile", safeMemberId);

        // ensure dir + quick write test
        try {
            Files.createDirectories(userDir);
            Path probe = userDir.resolve("__write_test__.tmp");
            Files.writeString(probe, "ok", StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            Files.deleteIfExists(probe);
        } catch (IOException e) {
            throw new RuntimeException("[WRITE TEST FAILED] Cannot write to " + userDir.toAbsolutePath()
                    + " | ex=" + e.getClass().getSimpleName() + " : " + e.getMessage(), e);
        }

        String ext = guessExtension(file.getOriginalFilename());
        String newName = UUID.randomUUID().toString().replace("-", "") + "." + ext.toLowerCase();
        Path dest = userDir.resolve(newName);

        try (InputStream in = file.getInputStream()) {
            Files.copy(in, dest, StandardCopyOption.REPLACE_EXISTING);
        } catch (FileSystemException e) {
            throw new RuntimeException("Cannot save upload file to " + dest.toAbsolutePath()
                    + " | ex=" + e.getClass().getSimpleName()
                    + " | reason=" + e.getReason()
                    + " | msg=" + e.getMessage(), e);
        } catch (IOException e) {
            throw new RuntimeException("Cannot save upload file to " + dest.toAbsolutePath()
                    + " | ex=" + e.getClass().getSimpleName()
                    + " | msg=" + e.getMessage(), e);
        }

        return "/uploads/profile/" + safeMemberId + "/" + newName;
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
