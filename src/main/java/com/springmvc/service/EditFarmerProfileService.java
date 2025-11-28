package com.springmvc.service;

import com.springmvc.model.Farmer;
import com.springmvc.model.HibernateConnection;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.io.IOException;
import java.nio.file.*;
import java.sql.*;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class EditFarmerProfileService {

    // อ้างอิง UPLOAD_DIR; ถ้าไม่ตั้ง จะเดา path ตาม OS
    private static Path resolveUploadBase() {
        String env = System.getenv("UPLOAD_DIR");
        if (env != null && !env.isBlank()) {
            return Paths.get(env).toAbsolutePath().normalize();
        }
        String os = System.getProperty("os.name", "").toLowerCase(Locale.ROOT);
        if (os.contains("win")) {
            return Paths.get("D:/Toos/png").toAbsolutePath().normalize();
        }
        return Paths.get("/app/uploads").toAbsolutePath().normalize();
    }

    private static final Path UPLOAD_BASE = resolveUploadBase();
    private static final String PUBLIC_PREFIX = "/uploads/";
    private static final Pattern DATA_TOO_LONG =
            Pattern.compile("Data too long for column '([^']+)'", Pattern.CASE_INSENSITIVE);

    /** โหลดโปรไฟล์เกษตรกร */
    public Farmer getCurrentProfile(String farmerId) {
        if (farmerId == null || farmerId.isBlank()) return null;

        final String sql = """
            SELECT farmerId, farmName, imageF, slipUrl, email, Address, password,
                   phoneNumber, rating, farmLocation, status
              FROM farmer
             WHERE farmerId = ?
        """;

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            return s.doReturningWork(conn -> {
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, farmerId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) return null;
                        Farmer f = new Farmer();
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
                        return f;
                    }
                }
            });
        } catch (Exception ex) {
            throw new RuntimeException("DB error while fetching farmer profile: " + ex.getMessage(), ex);
        }
    }

    /** โครงผลลัพธ์การบันทึก */
    public static class SaveResult {
        private final String imageUrl;
        private final String slipUrl;

        public SaveResult(String imageUrl, String slipUrl) {
            this.imageUrl = imageUrl;
            this.slipUrl = slipUrl;
        }
        public String getImageUrl() { return imageUrl; }
        public String getSlipUrl()  { return slipUrl;  }
    }

    /** อัปเดตโปรไฟล์ + เซฟไฟล์ภาพ (ถ้ามี) */
    public SaveResult updateProfile(Farmer f,
                                    MultipartFile farmImage,
                                    MultipartFile slipImage) {
        Objects.requireNonNull(f, "farmer must not be null");
        final String farmerId = f.getFarmerId();
        if (farmerId == null || farmerId.isBlank()) {
            throw new IllegalArgumentException("farmerId is required");
        }

        try { Files.createDirectories(UPLOAD_BASE); } catch (IOException ignore) {}

        // 1) คำนวณค่า URL ใหม่ (อาจถูกเปลี่ยนเมื่ออัปโหลด)
        String newImageUrl = nz(f.getImageF());
        String newSlipUrl  = nz(f.getSlipUrl());

        if (farmImage != null && !farmImage.isEmpty()) {
            newImageUrl = saveMultipart(farmImage, "profile/" + farmerId, randomName(farmImage));
            f.setImageF(newImageUrl);
        }
        if (slipImage != null && !slipImage.isEmpty()) {
            newSlipUrl  = saveMultipart(slipImage, "slip/" + farmerId, randomName(slipImage));
            f.setSlipUrl(newSlipUrl);
        }

        // ให้ lambda ใช้ตัวแปรที่เป็น final (แก้ effectively-final)
        final String imageUrlToSave = nz(newImageUrl);
        final String slipUrlToSave  = nz(newSlipUrl);

        // 2) อัปเดตฐานข้อมูล
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

        try (Session s = HibernateConnection.getSessionFactory().openSession()) {
            Transaction tx = s.beginTransaction();
            try {
                s.doWork(conn -> {
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, nz(f.getFarmName()));
                        ps.setString(2, imageUrlToSave);
                        ps.setString(3, slipUrlToSave);
                        ps.setString(4, nz(f.getEmail()));
                        ps.setString(5, nz(f.getAddress()));
                        ps.setString(6, nz(f.getPassword()));
                        ps.setString(7, nz(f.getPhoneNumber()));
                        ps.setString(8, nz(f.getFarmLocation()));
                        ps.setString(9, farmerId);
                        ps.executeUpdate();
                    }
                });
                tx.commit();
                return new SaveResult(imageUrlToSave, slipUrlToSave);
            } catch (Exception ex) {
                tx.rollback();
                String raw = ex.getMessage() == null ? "" : ex.getMessage();
                Matcher m = DATA_TOO_LONG.matcher(raw);
                if (m.find()) {
                    String col = m.group(1);
                    throw new RuntimeException("FIELD:" + col + "|ข้อมูลในช่อง " + col + " ยาวเกิน (สูงสุด 255 ตัวอักษร)", ex);
                }
                throw ex;
            }
        } catch (Exception ex) {
            throw new RuntimeException("DB error while updating profile: " + ex.getMessage(), ex);
        }
    }

    /* ================= Helpers ================= */

    private static String nz(String s) { return s == null ? "" : s.trim(); }

    /** สร้างชื่อไฟล์จาก UUID + นามสกุลเดิม (sanitize) */
    private static String randomName(MultipartFile file) {
        String ext = "";
        String orig = file.getOriginalFilename();
        if (orig != null) {
            int i = orig.lastIndexOf('.');
            if (i >= 0 && i < orig.length() - 1) {
                String raw = orig.substring(i + 1).toLowerCase(Locale.ROOT);
                raw = raw.replaceAll("[^a-z0-9]+", "");
                if (!raw.isEmpty()) ext = "." + raw;
            }
        }
        return UUID.randomUUID().toString().replace("-", "") + ext;
    }

    /** เซฟไฟล์ลงดิสก์และคืน path แบบ public (เช่น /uploads/slip/m001/xxx.png) */
    private static String saveMultipart(MultipartFile file, String subDir, String fileName) {
        String safeSub = subDir.replace("..", "").replace("\\", "/");
        Path dir = UPLOAD_BASE.resolve(safeSub).normalize();
        if (!dir.startsWith(UPLOAD_BASE)) {
            throw new IllegalArgumentException("Invalid upload path");
        }
        Path dst = dir.resolve(fileName).normalize();

        try {
            Files.createDirectories(dir);
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, dst, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException ioe) {
            throw new RuntimeException("Cannot save upload file to " + dst, ioe);
        }

        String publicPath = (PUBLIC_PREFIX + safeSub + "/" + fileName).replace("//", "/");
        if (!publicPath.startsWith("/uploads/")) {
            publicPath = "/uploads/" + publicPath.replaceFirst("^/+", "");
        }
        return publicPath;
    }
}
