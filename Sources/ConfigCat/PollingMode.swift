import Foundation

/// Describes a polling mode.
public class PollingMode : NSObject {
    func getPollingIdentifier() -> String {
        assert(false, "Method must be overidden!")
        return ""
    }
    
    func accept(visitor: PollingModeVisitor) -> RefreshPolicy {
        assert(false, "Method must be overidden!")
        return visitor.visit(pollingMode: ManualPollingMode())
    }
}

protocol PollingModeVisitor {
    func visit(pollingMode: AutoPollingMode) -> RefreshPolicy
    func visit(pollingMode: ManualPollingMode) -> RefreshPolicy
    func visit(pollingMode: LazyLoadingMode) -> RefreshPolicy
}

class AutoPollingMode : PollingMode {
    let autoPollIntervalInSeconds: Double
    let maxInitWaitTimeInSeconds: Int
    let onConfigChanged: ConfigCatClient.ConfigChangedHandler?

    init(autoPollIntervalInSeconds: Double = 60, maxInitWaitTimeInSeconds: Int = 5, onConfigChanged: ConfigCatClient.ConfigChangedHandler? = nil) {
        self.autoPollIntervalInSeconds = autoPollIntervalInSeconds
        self.maxInitWaitTimeInSeconds = maxInitWaitTimeInSeconds
        self.onConfigChanged = onConfigChanged
    }
    
    override func getPollingIdentifier() -> String {
        return "a"
    }
    
    override func accept(visitor: PollingModeVisitor) -> RefreshPolicy {
        return visitor.visit(pollingMode: self)
    }
}

class LazyLoadingMode : PollingMode {
    let cacheRefreshIntervalInSeconds: Double
    let useAsyncRefresh: Bool
    
    init(cacheRefreshIntervalInSeconds: Double = 60, useAsyncRefresh: Bool = false) {
        self.cacheRefreshIntervalInSeconds = cacheRefreshIntervalInSeconds
        self.useAsyncRefresh = useAsyncRefresh
    }
    
    override func getPollingIdentifier() -> String {
        return "l"
    }
    
    override func accept(visitor: PollingModeVisitor) -> RefreshPolicy {
        return visitor.visit(pollingMode: self)
    }
}


class ManualPollingMode : PollingMode {
    override func getPollingIdentifier() -> String {
        return "m"
    }
    
    override func accept(visitor: PollingModeVisitor) -> RefreshPolicy {
        return visitor.visit(pollingMode: self)
    }
}

class RefreshPolicyFactory : PollingModeVisitor {
    private let cache: ConfigCache?
    private let fetcher: ConfigFetcher
    private let sdkKey: String
    private let logger: Logger
    private let configJsonCache: ConfigJsonCache
    
    init(fetcher: ConfigFetcher, cache: ConfigCache? = nil, logger: Logger, configJsonCache: ConfigJsonCache, sdkKey: String) {
        self.fetcher = fetcher
        self.cache = cache
        self.sdkKey = sdkKey
        self.logger = logger
        self.configJsonCache = configJsonCache
    }
    
    func visit(pollingMode: AutoPollingMode) -> RefreshPolicy {
        return AutoPollingPolicy(cache: self.cache, fetcher: self.fetcher, logger: self.logger, configJsonCache: self.configJsonCache, sdkKey: self.sdkKey, config: pollingMode)
    }
    
    func visit(pollingMode: ManualPollingMode) -> RefreshPolicy {
        return ManualPollingPolicy(cache: self.cache, fetcher: self.fetcher, logger: self.logger, configJsonCache: self.configJsonCache, sdkKey: self.sdkKey)
    }
    
    func visit(pollingMode: LazyLoadingMode) -> RefreshPolicy {
        return LazyLoadingPolicy(cache: self.cache, fetcher: self.fetcher, logger: self.logger, configJsonCache: self.configJsonCache, sdkKey: self.sdkKey, config: pollingMode)
    }
}
