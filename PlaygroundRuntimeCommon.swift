// PlaygroundRuntime.swift provides the logging built-ins for playground.
//
// These functions are executed by the Standard Library for code compiled with
// the playground frontend action.
//
// @see the transform logic here
// https://github.com/apple/swift/blob/master/lib/Sema/PlaygroundTransform.cpp
// https://github.com/apple/swift/blob/e156713/test/PlaygroundTransform/Inputs/PlaygroundsRuntime.swift

func __builtin_log<T>(_ object: T, _ name: String, _ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api: "$builtin_log", object: object, name: name, range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

func __builtin_log_with_id<T>(_ object: T, _ name: String, _ id: Int, _ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api: "$builtin_log", object: object, name: name, id: id, range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

func __builtin_log_scope_entry(_ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api: "$builtin_log_scope_entry", range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

func __builtin_log_scope_exit(_ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api: "$builtin_log_scope_exit", range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

func __builtin_postPrint(_ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api: "$builtin_postPrint", range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

private struct SourceRange {
    let sl: Int
    let el: Int
    let sc: Int
    let ec: Int
    var text: String {
        return "[\(sl):\(sc)-\(el):\(ec)]"
    }
}

private final class LogRecord {
    let api: String
    let range: SourceRange
    let text: String
    let object: Any?

    init(api: String, object: Any, name: String, id: Int = -1, range: SourceRange) {
        var object_description: String = ""
        self.api = api
        self.range = range
        self.object = object
        print(object, terminator: "", to: &object_description)
        text = range.text + " " + api + " " + name + "=" + object_description
    }

    init(api: String, range: SourceRange) {
        self.api = api
        self.range = range
        self.object = nil
        text = range.text + " " + api
    }
}
