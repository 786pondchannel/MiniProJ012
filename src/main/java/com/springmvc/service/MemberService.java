package com.springmvc.service;

import com.springmvc.model.ConnectionDB;
import com.springmvc.model.Member;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
@Service 
public class MemberService {
    private ConnectionDB db = new ConnectionDB();

  
    /** สมัครสมาชิก (ทั้ง MEMBER และ FARMER) */
    public void register(Member m) {
        // 1) สร้าง ID อัตโนมัติ
        if (m.getMemberId() == null || m.getMemberId().isEmpty()) {
            m.setMemberId(UUID.randomUUID().toString());
        }

        // 2) เลือก INSERT ตาม status
        if ("FARMER".equalsIgnoreCase(m.getStatus())) {
            String sql = "INSERT INTO farmer("
                       + "farmerId, farmName, imageF, email, Address, password, phoneNumber, rating, farmLocation, status"
                       + ") VALUES(?,?,?,?,?,?,?,?,?,?)";
            try (Connection conn = db.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, m.getMemberId());
                ps.setString(2, m.getFarmName());
                ps.setString(3, null);                   // imageF ยังไม่มี
                ps.setString(4, m.getEmail());
                ps.setString(5, m.getAddress());
                ps.setString(6, m.getPassword());
                ps.setString(7, m.getPhoneNumber());
                ps.setString(8, null);                   // rating เริ่มต้น
                ps.setString(9, m.getFarmLocation());
                ps.setString(10, "FARMER");
                ps.executeUpdate();
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
        } else {
            String sql = "INSERT INTO member("
                       + "memberId, fullname, phoneNumber, imageUrl, address, password, email, status"
                       + ") VALUES(?,?,?,?,?,?,?,?)";
            try (Connection conn = db.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, m.getMemberId());
                ps.setString(2, m.getFullname());
                ps.setString(3, m.getPhoneNumber());
                ps.setString(4, m.getImageUrl());
                ps.setString(5, m.getAddress());
                ps.setString(6, m.getPassword());
                ps.setString(7, m.getEmail());
                ps.setString(8, "MEMBER");
                ps.executeUpdate();
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
        }
    }

    /** ดึงสมาชิกตามรหัส */
    public Member getById(String id) {
        String sql = "SELECT * FROM member WHERE memberId = ?";
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapMember(rs);
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }
        return null;
    }

    /** ดึงสมาชิกทั้งหมด */
    public List<Member> getAll() {
        String sql = "SELECT * FROM member";
        List<Member> list = new ArrayList<>();
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapMember(rs));
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }
        return list;
    }

    /** อัปเดตข้อมูลสมาชิก */
  
    public void update(Member m) {
        String sql = "UPDATE member SET fullname=?, phoneNumber=?, imageUrl=?, address=?, password=?, email=?, status=?"
                   + " WHERE memberId=?";
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, m.getFullname());
            ps.setString(2, m.getPhoneNumber());
            ps.setString(3, m.getImageUrl());
            ps.setString(4, m.getAddress());
            ps.setString(5, m.getPassword());
            ps.setString(6, m.getEmail());
            ps.setString(7, m.getStatus());
            ps.setString(8, m.getMemberId());

            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }
    }

    /** ลบสมาชิก */
    public void delete(String id) {
        String sql = "DELETE FROM member WHERE memberId = ?";
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }
    }

    /**
     * ล็อกอิน: ลองค้นทั้ง member และ farmer
     * @return Member หรือ null ถ้าไม่พบ
     */
    
    public Member authenticateByEmail(String email, String password) {
        // 1) ตรวจจากตาราง member
        String sqlMember = "SELECT memberId, fullname, phoneNumber, imageUrl, address, password, email, status "
                         + "FROM member WHERE email = ? AND password = ?";
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sqlMember)) {
            ps.setString(1, email);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Member m = mapMember(rs);
                    m.setStatus("MEMBER");
                    return m;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }

        // 2) ตรวจจากตาราง farmer
        String sqlFarmer = "SELECT farmerId AS memberId, farmName AS fullname, phoneNumber, imageF AS imageUrl, "
                         + "Address AS address, password, email, status, farmName, farmLocation "
                         + "FROM farmer WHERE email = ? AND password = ?";
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sqlFarmer)) {
            ps.setString(1, email);
            ps.setString(2, password);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Member m = new Member();
                    m.setMemberId(rs.getString("memberId"));
                    m.setFullname(rs.getString("fullname"));
                    m.setPhoneNumber(rs.getString("phoneNumber"));
                    m.setImageUrl(rs.getString("imageUrl"));
                    m.setAddress(rs.getString("address"));
                    m.setPassword(rs.getString("password"));
                    m.setEmail(rs.getString("email"));
                    m.setFarmName(rs.getString("farmName"));
                    m.setFarmLocation(rs.getString("farmLocation"));
                    m.setStatus("FARMER");
                    return m;
                }
            }
        } catch (SQLException ex) {
            throw new RuntimeException(ex);
        }

        // ไม่เจอทั้งคู่
        return null;
    }

    /** helper: map ผลลัพธ์จาก member → Member object */
    private Member mapMember(ResultSet rs) throws SQLException {
        Member m = new Member();
        m.setMemberId(rs.getString("memberId"));
        m.setFullname(rs.getString("fullname"));
        m.setPhoneNumber(rs.getString("phoneNumber"));
        m.setImageUrl(rs.getString("imageUrl"));
        m.setAddress(rs.getString("address"));
        m.setPassword(rs.getString("password"));
        m.setEmail(rs.getString("email"));
        // status & farmName/farmLocation จะ set ภายหลังใน caller
        return m;
    }
    /**
     * ตรวจสอบล็อกอิน (email + password)
     * @return Member object ถ้าถูกต้อง, null ถ้าไม่ถูกต้อง
     */
    public Member login(String email, String password) {
        String sql = "SELECT * FROM member WHERE email = ? AND password = ?";
        try (Connection conn = db.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Member m = new Member();
                    m.setMemberId(rs.getString("memberId"));
                    m.setFullname(rs.getString("Fullname"));
                    m.setEmail(rs.getString("email"));
                    m.setImageUrl(rs.getString("imageUrl"));
                    // ... เซ็ต field อื่น ๆ ตามต้องการ
                    return m;
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("Login error", e);
        }
        return null;
    }
}