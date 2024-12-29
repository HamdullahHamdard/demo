package com.example.demo;

import net.devh.boot.grpc.server.config.GrpcServerProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(GrpcServerProperties.class)
public class GrpcServerConfig {
}

