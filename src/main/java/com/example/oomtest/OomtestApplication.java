package com.example.oomtest;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.util.ArrayList;
import java.util.List;

@SpringBootApplication
public class OomtestApplication {

    public static void main(String[] args) {
        SpringApplication.run(OomtestApplication.class, args);
//        causeOutOfMemory();
    }
//    private static void causeOutOfMemory() {
//        List<Object> list = new ArrayList<>();
//        while (true) {
//            list.add(new Object());
//        }
//    }
}
