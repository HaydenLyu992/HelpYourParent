package com.hyp.common;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class BusinessException extends RuntimeException {
    private final int code;
    private final HttpStatus httpStatus;

    public BusinessException(int code, String message) {
        this(code, message, HttpStatus.BAD_REQUEST);
    }

    public BusinessException(int code, String message, HttpStatus httpStatus) {
        super(message);
        this.code = code;
        this.httpStatus = httpStatus;
    }

    public BusinessException(String message) {
        this(400, message, HttpStatus.BAD_REQUEST);
    }

    public static BusinessException notFound(String entity) {
        return new BusinessException(404, entity + " 不存在", HttpStatus.NOT_FOUND);
    }

    public static BusinessException alreadyExists(String entity) {
        return new BusinessException(409, entity + " 已存在", HttpStatus.CONFLICT);
    }

    public static BusinessException invalidCode() {
        return new BusinessException(400, "验证码错误或已过期");
    }
}
