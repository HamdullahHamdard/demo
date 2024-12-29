package com.example.demo;
import java.util.concurrent.ConcurrentLinkedQueue;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import com.example.grpc.Empty;
import com.example.grpc.MessageRequest;
import com.example.grpc.MessageResponse;
import com.example.grpc.SignalingServiceGrpc;

import io.grpc.stub.StreamObserver;
import net.devh.boot.grpc.server.service.GrpcService;

@SpringBootApplication
public class DemoApplication {

	
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GrpcService
    public static class SignalingServiceImpl extends SignalingServiceGrpc.SignalingServiceImplBase {
        private final ConcurrentLinkedQueue<String> messages = new ConcurrentLinkedQueue<>();

        @Override
        public void sendMessage(MessageRequest request, StreamObserver<MessageResponse> responseObserver) {
            String content = request.getContent();
            messages.offer(content);
            
            MessageResponse response = MessageResponse.newBuilder()
                    .setContent("Message received: " + content)
                    .build();
            responseObserver.onNext(response);
			System.out.println("__________________________________________ This is sending");
            responseObserver.onCompleted();
        }

        @Override
        public void receiveMessages(Empty request, StreamObserver<MessageResponse> responseObserver) {
            while (true) {
                String message = messages.poll();
                if (message != null) {
                    MessageResponse response = MessageResponse.newBuilder()
                            .setContent(message)
                            .build();
                    responseObserver.onNext(response);
					System.out.println("__________________________________________ This is reciving");
                }
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    responseObserver.onError(e);
					System.out.println("__________________________________________ This is Exception");
                    return;
                }
            }
        }
    }

}
