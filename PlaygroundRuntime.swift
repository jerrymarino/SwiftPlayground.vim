// PlaygroundRuntime.swift provides the logging built-ins for playground.
//
// These functions are executed by the Standard Library for code compiled with
// the playground frontend action.
//
// @see the transform logic here
// https://github.com/apple/swift/blob/master/lib/Sema/PlaygroundTransform.cpp
// https://github.com/apple/swift/blob/e156713/test/PlaygroundTransform/Inputs/PlaygroundsRuntime.swift

func __builtin_send_data(_ object: AnyObject?) {
    let record = object as! LogRecord
    guard record.api == "$builtin_log" else { return }

    print(record.text)
}
