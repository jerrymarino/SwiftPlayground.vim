// PlaygroundRuntime.swift provides the logging built-ins for playground.
//
// These functions are executed by the Standard Library for code compiled with
// the playground frontend action.
//
// @see the transform logic here
// https://github.com/apple/swift/blob/master/lib/Sema/PlaygroundTransform.cpp

struct SourceRange {
    let sl: Int
    let el: Int
    let sc: Int
    let ec: Int
    var text: String {
        return "[\(sl):\(sc)-\(el):\(ec)]"
    }
}

class LogRecord {
    let text: String
    let api: String

    init(api: String, object: Any, name: String, id: Int, range: SourceRange) {
        var object_description: String = ""
        self.api = api
        print(object, terminator: "", to: &object_description)
        text = range.text + " " + api + " " + name + "=" + object_description
    }
    init(api: String, object: Any, name: String, range: SourceRange) {
        var object_description: String = ""
        self.api = api
        print(object, terminator: "", to: &object_description)
        text = range.text + " " + api + " " + name + "=" + object_description
    }
    init(api: String, object: Any, range: SourceRange) {
        var object_description: String = ""
        self.api = api
        print(object, terminator: "", to: &object_description)
        text = range.text + " " + api + " " + object_description
    }
    init(api: String, range: SourceRange) {
        self.api = api
        text = range.text + " " + api
    }
}

func __builtin_log<T>(_ object: T, _ name: String, _ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api:"$builtin_log", object: object, name: name, range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

func __builtin_log_with_id<T>(_ object: T, _ name: String, _ id: Int, _ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api:"$builtin_log", object: object, name: name, id: id, range: SourceRange(sl: sl, el: el, sc: sc, ec: ec))
}

func __builtin_log_scope_entry(_ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api:"$builtin_log_scope_entry", range: SourceRange(sl:sl, el:el, sc:sc, ec:ec))
}

func __builtin_log_scope_exit(_ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api:"$builtin_log_scope_exit", range: SourceRange(sl:sl, el:el, sc:sc, ec:ec))
}

func __builtin_postPrint(_ sl: Int, _ el: Int, _ sc: Int, _ ec: Int) -> AnyObject? {
    return LogRecord(api:"$builtin_postPrint", range: SourceRange(sl:sl, el:el, sc:sc, ec:ec))
}

func __builtin_send_data(_ object: AnyObject?) {
    let record = object as! LogRecord
    if record.api != "$builtin_log" {
        return
    }

    print(record.text)
}
