use std::os::raw::c_char;
use std::ffi::CStr;
use std::ffi::CString;

#[macro_use]
extern crate serde_derive;
extern crate serde;
//on rust 1.33 not sure why the boss is making me use externs
use serde::{Deserialize, Serialize};

fn increment(data: String) -> String {
    //deserialize the string for type checking
    #[derive(Serialize, Deserialize)]
    struct Arguments {
        digit: i64
    }

    let mut argument: Arguments = match serde_json::from_str(&data) {
        Err(err) => return format!("failed to parse arguments, {}", err).to_string(),
        Ok(data) => data
    };

    argument.digit += 1;

    /* can serialize on the way out, though I think that makes dart work too hard
    let output = json!({
        "digit": argument.digit
    });

    return output.to_string();
    */

    argument.digit.to_string()    
}


//main function
fn switch(function: String, arguments: String) -> String {
    //return error for bad function here, return error for bad args in each function after deserialization
    let result = match function.as_str() {
        //"increment" => result = increment(arguments),
        "increment" => increment(arguments),
        _ => format!("cannot find rust function branch matching {}", function).to_string()
    };
    result
}

// Universal Interface
#[no_mangle]
pub extern "C" fn rusted(function_pointer: *const c_char, argument_pointer: *const c_char) -> CString {
    let function_cstring = unsafe { CStr::from_ptr(function_pointer) };
    let function = match function_cstring.to_str() {
        Err(_) => return CString::new("the function cstr would not convert to rust str").expect("failed to convert incoming function string to internal string"),
        Ok(function) => function.to_owned(),
    };

    let argument_cstring = unsafe { CStr::from_ptr(argument_pointer) };
    let argument = match argument_cstring.to_str() {
        Err(_) => return CString::new("the argument cstr would not convert to rust string").expect("falide to convert incoming argument string to internal string"),
        Ok(argument) => argument.to_owned(),
    };

    //might need to drop the pointed string somehow
    //drop(Box::from_raw(c_str))

    let output = switch(function, argument);
    CString::new(output).expect("failed to convert outgoing internal string to CString")

}

/// Java Interface
#[cfg(target_os="android")]
#[allow(non_snake_case)]
pub mod android {
    extern crate jni;

    use super::*;
    use self::jni::JNIEnv;
    use self::jni::objects::{JClass, JString};
    use self::jni::sys::jstring;
    #[no_mangle]
    pub unsafe extern "C" fn Java_com_example_rusty_1flutter_MainActivity_rusted(env: JNIEnv, _: JClass, java_function: JString, java_arguments: JString) -> jstring {
        let function = env.get_string(java_function).expect("invalid function string");
        let arguments = env.get_string(java_arguments).expect("invalid argument string");
        let result = rusted(function.as_ptr(), arguments.as_ptr());
        let output = env.new_string(result.to_str().expect("failed to convert CSTring to str for jstring"))
            .expect("Couldn't create java string!");
        output.into_inner()

    }
}
