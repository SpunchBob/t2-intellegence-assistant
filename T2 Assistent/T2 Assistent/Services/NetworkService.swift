//
//  NetworkService.swift
//  T2 Assistent
//
//  Created by Максим Бондарев on 22/1/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case unknown(Error)
}

class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "https://api.tele2.ru" // Замените на реальный URL
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Добавляем заголовки авторизации и другие
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Добавляем тело запроса
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "NetworkError", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    // Метод для загрузки данных без декодирования
    func requestData(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "NetworkError", code: -1))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
}
