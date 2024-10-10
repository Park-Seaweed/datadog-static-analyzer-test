package com.example.oomtest.Controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api")
class OomTestController {
    private static final Logger logger = LoggerFactory.getLogger(OomTestController.class);
    // OOM 발생 엔드포인트
    @GetMapping("/oom-test")
    public String causeOutOfMemory() {
        List<Object> list = new ArrayList<>();
        try {
            while (true) {
                list.add(new Object());
            }
        } catch (OutOfMemoryError e) {
            logger.error("Out of memory error occurred during test!", e);
            return "An OutOfMemoryError occurred. Check server logs for details.";
        }
    }

    // 헬스체크 엔드포인트
    @GetMapping("/health")
    public String healthCheck() {
        return "Application is healthy";
    }
}

