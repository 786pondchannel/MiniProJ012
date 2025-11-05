package com.springmvc.config;

import org.springframework.web.filter.CharacterEncodingFilter;
import org.springframework.web.servlet.support.AbstractAnnotationConfigDispatcherServletInitializer;

import jakarta.servlet.Filter;
import jakarta.servlet.MultipartConfigElement;
import jakarta.servlet.ServletRegistration;

public class SpringMVCDispatcherServletInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {

    // ใช้ temp ของระบบ (Windows/Unix จะมีเสมอ)
    private static final String LOCATION = System.getProperty("java.io.tmpdir");
    private static final long MAX_FILE_SIZE = 20_000_000;   // 20MB
    private static final long MAX_REQUEST_SIZE = 40_000_000; // 40MB
    private static final int FILE_SIZE_THRESHOLD = 0;

    @Override
    protected Class<?>[] getRootConfigClasses() { return new Class[0]; }

    @Override
    protected Class<?>[] getServletConfigClasses() { return new Class[] { WebConfig.class }; }

    @Override
    protected String[] getServletMappings() { return new String[] { "/" }; }

    @Override
    protected Filter[] getServletFilters() {
        CharacterEncodingFilter f = new CharacterEncodingFilter();
        f.setEncoding("UTF-8");
        f.setForceEncoding(true);
        return new Filter[] { f };
    }

    @Override
    protected void customizeRegistration(ServletRegistration.Dynamic registration) {
        MultipartConfigElement multipartConfig =
            new MultipartConfigElement(LOCATION, MAX_FILE_SIZE, MAX_REQUEST_SIZE, FILE_SIZE_THRESHOLD);
        registration.setMultipartConfig(multipartConfig);
    }
}
