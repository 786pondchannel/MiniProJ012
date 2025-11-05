package com.springmvc.service;

import com.springmvc.model.ConnectionDB;
import com.springmvc.model.Farmer;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.*;
import java.sql.*;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class EditFarmerProfileService {

    // ต้องตรงกับ WebConfig: /uploads/** -> file:///D:/Toos/png/
    private static final String UPLOAD_ROOT = "D:/Toos/png/";
    private static final String PUBLIC_PREFIX = "uploads/";

    // จับ error Data too long เพื่อบอกช่องที่ผิด
    private static final Pattern DATA_TOO_LONG =
            Pattern.compile("Data too long for column '([^']+)'", Pattern.CASE_INSENSITIVE);

    /** โหลดโปรไฟล์เกษตรกร */
    public Farmer getCurrentProfile(String farmerId) {
        Farmer f = null;
        final String sql = """
            SELECT farmerId, farmName, imageF, slipUrl, email, Address, password,
                   phoneNumber, rating, farmLocation, status
              FROM farmer
             WHERE farmerId = ?
        """;
        try (Connection conn = new ConnectionDB().getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, farmerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    f = new Farmer();
                    f.setFarmerId(rs.getString("farmerId"));
                    f.setFarmName(rs.getString("farmName"));
                    f.setImageF(rs.getString("imageF"));
                    f.setSlipUrl(rs.getString("slipUrl"));
                    f.setEmail(rs.getString("email"));
                    f.setAddress(rs.getString("Address"));
                    f.setPassword(rs.getString("password"));
                    f.setPhoneNumber(rs.getString("phoneNumber"));
                    f.setRating(rs.getString("rating"));
                    f.setFarmLocation(rs.getString("farmLocation"));
                    f.setStatus(rs.getString("status"));
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException("DB error while fetching farmer profile: " + ex.getMessage(), ex);
        }
        return f;
    }

    /** โครงผลลัพธ์การบันทึก */
    public static class SaveResult {
        private final String imageUrl;  // path public ของรูปฟาร์ม
        private final String slipUrl;   // path public ของสลิป/QR
        public SaveResult(String imageUrl, String slipUrl) { this.imageUrl = imageUrl; this.slipUrl = slipUrl; }
        public String getImageUrl() { return imageUrl; }
        public String getSlipUrl()  { return slipUrl;  }
    }

    /**
     * อัปเดตโปรไฟล์ + บันทึกรูป (ถ้ามี)
     * - Address รองรับ 255 ตัวอักษร (ตาม ALTER TABLE)
     * - slipUrl ถูกบันทึกลง DB (ไม่หายเมื่อรีเฟรช)
     */
    public SaveResult updateProfile(Farmer f,
                                    MultipartFile farmImage,
                                    MultipartFile slipImage) {
        Objects.requireNonNull(f, "farmer must not be null");
        final String farmerId = f.getFarmerId();

        // 1) บันทึกไฟล์ก่อนเพื่อได้ path
        String newImageUrl = f.getImageF();   // คงค่าเดิมถ้าไม่เปลี่ยน
        String newSlipUrl  = f.getSlipUrl();  // คงค่าเดิมถ้าไม่อัปโหลดใหม่

        if (farmImage != null && !farmImage.isEmpty()) {
            newImageUrl = saveMultipart(farmImage, "profile/" + farmerId, randomName(farmImage));
            f.setImageF(newImageUrl);
        }
        if (slipImage != null && !slipImage.isEmpty()) {
            newSlipUrl  = saveMultipart(slipImage, "slip/" + farmerId, randomName(slipImage));
            f.setSlipUrl(newSlipUrl);
        }

        // 2) อัปเดตฐานข้อมูล (เก็บ slipUrl ลง DB ด้วย)
        final String sql = """
            UPDATE farmer
               SET farmName     = ?,
                   imageF       = ?,
                   slipUrl      = ?,
                   email        = ?,
                   Address      = ?,
                   password     = ?,
                   phoneNumber  = ?,
                   farmLocation = ?
             WHERE farmerId     = ?
        """;
        try (Connection conn = new ConnectionDB().getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, nz(f.getFarmName()));
            ps.setString(2, nz(newImageUrl));
            ps.setString(3, nz(newSlipUrl));
            ps.setString(4, nz(f.getEmail()));
            ps.setString(5, nz(f.getAddress()));
            ps.setString(6, nz(f.getPassword()));
            ps.setString(7, nz(f.getPhoneNumber()));
            ps.setString(8, nz(f.getFarmLocation()));
            ps.setString(9, farmerId);

            ps.executeUpdate();
            return new SaveResult(newImageUrl, newSlipUrl);

        } catch (SQLException ex) {
            String raw = ex.getMessage() == null ? "" : ex.getMessage();
            Matcher m = DATA_TOO_LONG.matcher(raw);
            if (m.find()) {
                String col = m.group(1);
                throw new RuntimeException("FIELD:" + col + "|ข้อมูลในช่อง " + col + " ยาวเกิน (สูงสุด 255 ตัวอักษร)", ex);
            }
            throw new RuntimeException("DB error while updating profile: " + raw, ex);
        }
    }

    /* ===== helpers ===== */

    private String nz(String s) { return s == null ? "" : s.trim(); }

    /** ชื่อไฟล์จาก UUID + นามสกุลเดิม */
    private String randomName(MultipartFile file) {
        String orig = file.getOriginalFilename();
        String ext = "";
        if (orig != null) {
            int i = orig.lastIndexOf('.');
            if (i >= 0) ext = orig.substring(i);
        }
        return UUID.randomUUID().toString().replace("-", "") + ext.toLowerCase();
    }

    /** เซฟไฟล์แล้วคืน path public (เช่น uploads/slip/m001/abc.png) */
    private String saveMultipart(MultipartFile file, String subDir, String fileName) {
        Path dir = Paths.get(UPLOAD_ROOT, subDir);
        Path dst = dir.resolve(fileName);
        try {
            if (!Files.exists(dir)) Files.createDirectories(dir);
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, dst, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException ioe) {
            throw new RuntimeException("Cannot save upload file to " + dst, ioe);
        }
        return PUBLIC_PREFIX + subDir.replace('\\', '/') + "/" + fileName;
    }
}
