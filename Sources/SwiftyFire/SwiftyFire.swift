import Foundation
import Logging

public protocol SwiftyFireDelegate {
    func didSuccessfullyAuthenticate(connection: SwiftyFire)
    func authenticationFailure(error: Error)
}

public final class SwiftyFire {
    public typealias SFCallback = ((Value?, Error?) -> Void)
    private let secrets: SFSecrets
    public var delegate: SwiftyFireDelegate?
    private var logger = PrintLogger()

    public init(private_key: String, service_account: String, db_url: String, delegate: SwiftyFireDelegate) {
        self.delegate = delegate
        self.secrets = SFSecrets(url: db_url, private_key: private_key, service_account: service_account)
        logger.debug("SwiftyFire initialized")
    }

    deinit {
        logger.debug("Deinit called")
        delegate = nil
    }

    public func setup(completion: @escaping (GoogleAccessToken?, Error?) -> Void) {
        logger.debug("SwiftyFire attempting setup")
        secrets.getGoogleAuthToken { [weak self] (token, err) in
            guard let self = self else { return }
            if token != nil {
                self.delegate?.didSuccessfullyAuthenticate(connection: self)
            }
            if let err = err {
                self.delegate?.authenticationFailure(error: err)
            }
            completion(token, err)
        }
    }

    // MARK: - Public Methods

    /// Issue a post request. The returned dictionary will be of the format { "name": <auto generated id> }.
    /// the value will be the key at which you may access your saved data. i.e. /path/to/<auto generated id>
    ///
    /// - Parameters:
    ///   - path: desired location of data
    ///   - val: data to be saved
    ///   - completion: callback function with an optional value of the data just saved and optional error
    public func post(path: String, val: [String: AnyObject], completion: @escaping SFCallback) {
        write(path, val, "POST", completion)
    }


    /// Issue a patch request. Patch is a non-destructive request, meaning it will not overwrite that node with your data.
    ///
    /// - Parameters:
    ///   - path: desired location of data
    ///   - val: data to be saved
    ///   - completion: callback function with an optional value of the data just saved and optional error
    public func patch(path: String, val: [String: AnyObject], completion: @escaping SFCallback) {
        write(path, val, "PATCH", completion)
    }

    /// Issue a patch request. Put is a destructive request, meaning it will overwrite that node with your data.
    ///
    /// - Parameters:
    ///   - path: desired location of data
    ///   - val: data to be saved
    ///   - completion: callback function with an optional value of the data just saved and optional error
    public func put(path: String, val: [String: AnyObject], completion: @escaping SFCallback) {
        write(path, val, "PUT", completion)
    }

    /// Issue a get request. Retrieve the data at that location
    ///
    /// - Parameters:
    ///   - path: location of desired data
    ///   - completion: callback function with an optional value and optional error
    public func get(path: String, completion: @escaping SFCallback) {
        read(path, completion)
    }

    /// Issue a delete request. Delete the data at that location
    ///
    /// - Parameters:
    ///   - path: location of data to be deleted
    ///   - completion: callback function with an optional value and optional error
    public func delete(path: String, completion: @escaping SFCallback) {
        let urlString = buildURLString(path: path)
        guard let url = URL(string: urlString) else {
            completion(.null, SwiftyFireError.invalidURLString)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            if let error = error {
                completion(.null, error)
                return
            }
            if let response = response as? HTTPURLResponse {
                if let error = self.parseStatusCodes(code: response.statusCode) {
                    completion(.null, error)
                }
            }

            if data != nil {
                completion(.null, SwiftyFireError.notFound)
            }

            }.resume()
    }

    // MARK: - Helper Methods

    private func read(_ path: String, _ completion: @escaping SFCallback) {
        let urlString = buildURLString(path: path)
        guard let url = URL(string: urlString) else {
            completion(.null, SwiftyFireError.invalidURLString)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            if let error = error {
                completion(.null, error)
                return
            }
            if let response = response as? HTTPURLResponse {
                if let error = self.parseStatusCodes(code: response.statusCode) {
                    completion(.null, error)
                }
            }

            if let data = data {
                if let json = self.process(data: data) {
                    print(json)
                    completion(self.process(data: json), nil)
                } else {
                    completion(.null, SwiftyFireError.notFound)
                }
            }

        }.resume()
    }

    private func write(_ path: String, _ val: [String: AnyObject], _ httpMethod: String, _ completion: @escaping SFCallback) {
        let urlString = buildURLString(path: path)
        guard let url = URL(string: urlString) else {
            completion(nil, SwiftyFireError.invalidURLString)
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = httpMethod
        req.httpBody = try? JSONSerialization.data(withJSONObject: val, options: .prettyPrinted)
        URLSession.shared.dataTask(with: req) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }

            if let response = response as? HTTPURLResponse {
                if let error = self.parseStatusCodes(code: response.statusCode) {
                    completion(nil, error)
                }
            }

            if let data = data {
                if let json = self.process(data: data) {
                    print(json)
                    completion(self.process(data: json), nil)
                } else {
                    completion(.null, SwiftyFireError.notFound)
                }
            }

            }.resume()
    }

    private func buildURLString(path: String) -> String {
        var urlString = "\(secrets.databaseURL)/\(path).json"
        urlString.append(buildAuthParam())
        return urlString
    }

    private func buildAuthParam() -> String {
        guard let token = secrets._access_token else {
            delegate?.authenticationFailure(error: SwiftyFireError.authenticationTokenWasNotRefreshed)
            return ""
        }
        return "?access_token=\(token.access_token)"
    }

    private func parseStatusCodes(code: Int) -> SwiftyFireError? {
        if (code == 200) { return nil }
        else if (code == 400) { return .badRequest }
        else if (code == 401) { return .unauthorized}
        else if (code == 404) { return .notFound }
        else if (code == 500) { return .serverError }
        else if (code == 503) { return .databaseUnavailable }
        else { return .unknownError }
    }

    private func process(data: Data) -> Any? {
        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
            return json
        } else if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) {
            return json
        } else if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
            return json
        }
        return nil
    }

    private func process(data: Any) -> Value {
        if let val = data as? String { return .string(val: val) }
        else if let val = data as? Int { return .number(val: val) }
        else if let val = data as? Bool { return .bool(val: val) }
        else if let val = data as? [String: AnyObject] { return .dictionary(val : val) }
        else { return .null }
    }
}
