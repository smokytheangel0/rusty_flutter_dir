use std::os::raw::c_char;
use std::ffi::CStr;
use std::ffi::CString;
use std::env;
use std::fs::File;
use std::fs;
use std::collections::VecDeque;
use std::any::{Any, TypeId};
use std::boxed::Box;


extern crate rusqlite;

use rusqlite::{Connection, NO_PARAMS, MappedRows, Row, params, ToSql};
use rusqlite::types::ToSqlOutput;
use rusqlite::types::Value as SqlValue;

#[macro_use]
extern crate serial_test_derive;
use serial_test_derive::serial;


#[macro_use]
extern crate serde_derive;
extern crate serde_json;
extern crate serde;
use serde_json::Value;
use serde::{Deserialize, Serialize};

//TODO
//conquer dynamic crate and allow multityped rows
//possibly using type_info to wrangle out specific types
//clean up interfaces with FlutterResults

fn store(data: &String) -> FlutterResult {
    #[derive(Deserialize)]
    struct Arguments {
        table: String,
        data: Vec<Value>,
        path: String
    }

    let arguments: Arguments = match serde_json::from_str(&data) {
        Ok(data) => data,
        Err(err) => return FlutterResult!{"Err()", format!("failed to parse arguments\n, {}", err)}
    };


    let storage = match Connection::open(format!("{}/test.db", arguments.path)) {
        Ok(storage) => storage,
        Err(err) => return FlutterResult!{"Err()", format!("failed to open connection to db: {:?}", err)}
    };

    //this can definitely be optimized to return a single result instead of the entire table
    let statement = match storage.prepare(&format!("SELECT * FROM {}", arguments.table)) {
        Ok(statement) => statement,
        Err(err) => return FlutterResult!{"Err()", format!("failed to prepare column identifying statement: {:?}", err)}
    };   
    
    let columns: Vec<&str> = statement.column_names();

    let storage = match Connection::open(format!("{}/test.db", arguments.path)) {
        Ok(storage) => storage,
        Err(err) => return FlutterResult!{"Err()", format!("failed to open connection to db: {:?}", err)}
    };

    let mut column_values: Vec<SqlValue> = vec![];
    //parse out input value types and construct a string containing them and \""'s
    for value in 0..arguments.data.len() {
        if arguments.data[value].is_string() {
            match arguments.data[value].as_str() {
                Some(string) => column_values.push(SqlValue::Text(string.to_owned())),
                None => return FlutterResult!{"Err()", format!("impossible input value at position {}: {:?}", value, arguments.data[value])}
            }
        } else if arguments.data[value].is_i64() {
            match arguments.data[value].as_i64() {
                Some(int) => column_values.push(SqlValue::Integer(int)),
                None => return FlutterResult!{"Err()", format!("impossible input value at position {}: {:?}", value, arguments.data[value])}
            }
        } else if arguments.data[value].is_f64() {
            match arguments.data[value].as_f64() {
                Some(float) => column_values.push(SqlValue::Real(float)),
                None => return FlutterResult!{"Err()", format!("impossible input value at position {}: {:?}", value, arguments.data[value])}
            }
        } else {
            return FlutterResult!("Err()", format!("the only types accepted for storage right now are String, Floating Point and Integer"))
        }
    }

    //create question mark string according to how many values are present
    let mut interro_string = "".to_owned();
    for number in 0..columns.len() {
        if number != 0 {
            interro_string = format!("{}, ?{}", interro_string, number + 1).to_owned();
        } else {
            interro_string = "?1".to_owned();
        }
    }

    let table_statement = format!("INSERT INTO {} ({}) VALUES ({})", arguments.table, columns.join(","), interro_string);

    let mut statement = match storage.prepare(&table_statement){
        Ok(statement) => statement,
        Err(err) => return FlutterResult!{"Err()", format!("failed to prepare the insertion statment: {:?}", err)}
    };

    match statement.execute(column_values) {
        Ok(_) => (),
        Err(err) => return FlutterResult!{"Err()", format!("failed to write to db: {:?}", err)}
    };

    match statement.finalize() {
        Ok(_) => (),
        Err(err) => return FlutterResult!{"Err()", format!("failed to close the db: {:?}", err)}
    };

    FlutterResult!{"Ok()", "successfully wrote to db"}
}

fn search_storage(data: &String) -> FlutterResult {
    #[derive(Deserialize)]
    struct Arguments {
        query: String,
        data: Vec<String>,
        path: String
    };

    let arguments: Arguments = match serde_json::from_str(&data) {
        Ok(data) => data,
        Err(err) => return FlutterResult!{"Err", format!("failed to parse arguments\n, {}", err)}
    };

    let storage = match Connection::open(format!("{}/test.db", arguments.path)) {
        Ok(storage) => storage,
        Err(err) => return FlutterResult!{"Err()", format!("failed to open connection to db: {:?}", err)}
    };

    let mut statement = match storage.prepare(&arguments.query) {
        Ok(statement) => statement,
        Err(err) => return FlutterResult!{"Err()", format!("failed to prepare column identifying statement: {:?}", err)}
    };

    let mut borrowed_rows = match statement.query(arguments.data) {
        Ok(statement) => statement,
        Err(err) => return FlutterResult!{"Err()", format!("failed to query database: {:?}", err)}
    };

    let mut owned_rows = vec![];

    while let Some(row) = match borrowed_rows.next(){
                                                        Ok(row) => row,
                                                        Err(err) => return FlutterResult!{"Err()", format!("failed to select the next row: {:?}", err)}
                                                    } 
    {
        owned_rows.push(match row.get(0) {
            Ok(owned_row) => owned_row,
            Err(err) => return FlutterResult!{"Err()", format!("failed to get the current row: {:?}", err)}
        });
    }

    //out goal is to return:
    //"result": "Ok()" || "Err()", "data:"


    FlutterResult{
        result: "Ok()",
        data: owned_rows
    }
}

fn init_storage(data: &String) -> FlutterResult {
    #[derive(Deserialize)]
    struct Arguments {
        table: String,
        columns: String,
        path: String
    }

    let arguments: Arguments = match serde_json::from_str(&data) {
        Ok(data) => data,
        Err(err) => return FlutterResult!{"Err()", format!("failed to parse arguments\n, {}", err)}
    };


    let storage = match Connection::open(format!("{}/test.db", arguments.path)) {
        Ok(storage) => storage,
        Err(err) => return FlutterResult!{"Err()", format!("failed to open connection to db: {:?}", err)}
    };
    
    let table_statement = format!("CREATE TABLE IF NOT EXISTS {} ({})", arguments.table, arguments.columns);

    match storage.execute(&table_statement, NO_PARAMS) {
        Ok(_) => (),
        Err(err) => return FlutterResult!{"Err()", format!("failed to create table: {:?}", err)}
    };

    match storage.close() {
        Ok(_) => (),
        Err(err) => return FlutterResult!{"Err()", format!("failed to close the db: {:?}", err)}
    };

    FlutterResult!{
        "Ok()",
        format!("created the table: {} successfully with columns: {}", arguments.table, arguments.columns)
    }
}

fn delete_storage(data: &String) -> FlutterResult {
    #[derive(Deserialize)]
    struct Arguments {
        path: String
    }

    let arguments: Arguments = match serde_json::from_str(&data) {
        Ok(data) => data,
        Err(err) => return FlutterResult!{"Err()", format!("failed to parse arguments\n, {}", err)}
    };

    match File::open(format!("{}/test.db", arguments.path)) {
        Err(err) => return FlutterResult!{"Err()", format!("file not found: {}", err)},
        Ok(_) => match fs::remove_file("test.db") {
            Ok(_) => (),
            Err(err) => return FlutterResult!{"Err()", format!("failed to remove file even after it was located: {}", err)}
        }
    };

    FlutterResult!{
        "Ok()",
        "successfully removed file"
    }

}

fn increment(data: &String) -> FlutterResult {
    //deserialize the string for type checking
    #[derive(Serialize, Deserialize)]
    struct Arguments {
        digit: i64
    }

    let mut arguments: Arguments = match serde_json::from_str(&data) {
        Ok(data) => data,
        Err(err) => return FlutterResult!{"Err()", format!("failed to parse arguments\n, {}", err)}
    };

    arguments.digit += 1;

    /* can serialize on the way out, though I think that makes dart work too hard
    let output = json!({
        "digit": arguments.digit
    });

    return output.to_string();
    */
    FlutterResult!{"Ok()", arguments.digit}
}

fn hello(data: &String) -> FlutterResult {
    #[derive(Serialize, Deserialize)]
    struct Arguments {
        name: String,
    }

    let mut arguments: Arguments = match serde_json::from_str(&data) {
        Ok(data) => data,
        Err(err) => return FlutterResult!{"Err()", format!("failed to parse arguments\n, {}", err)}
    };

    arguments.name = format!("hello {}!", arguments.name);

    FlutterResult!{"Ok()", arguments.name}
}

#[derive(Serialize, Deserialize)]
struct FlutterResult {
    result: &'static str,
    data: Vec<String>
}

#[macro_export]
macro_rules! FlutterResult {
    ($result:expr, $data:expr) => {
        FlutterResult{result: $result, data: vec![$data.to_string()]}
    };
}


//main function
fn switch(function: String, arguments: String) -> String {
    //return error for bad function here, return error for bad args in each function after deserialization
    let result = match function.as_str() {
        //"increment" => result = increment(arguments),
        "increment" => increment(&arguments),
        "store" => store(&arguments),
        "search_storage" => search_storage(&arguments),
        "init_storage" => init_storage(&arguments),
        "delete_storage" => delete_storage(&arguments),
        "hello" => hello(&arguments),
        _ => FlutterResult!{"Err()", format!("cannot find rust function branch matching {}", function)}
    };
    //for this result, because dart dynamically decodes json, we should be able to encode a struct
    //with a result field and a data field or a result field and an Ok or Err dict inside
    //this will allow the flutter user to handle errors less opaquely on their side, simply matching
    //on the contents of the result field, Err() or Ok()
    //and then using the data field appropriately as needed b4./9bg rugb.r hc.eh d;
    let output = match serde_json::to_string(&result) {
        Ok(output) => output,
        Err(err) => "{'result' : 'Err()', 'data': 'failed exit encoding!!!'}".to_string()
    };
    output
}

// Universal Interface
#[no_mangle]
pub extern "C" fn rusted(function_pointer: *const c_char, argument_pointer: *const c_char) -> CString {
    let function_cstring = unsafe { CStr::from_ptr(function_pointer) };

    let function = match function_cstring.to_str() {
        Err(_) => return CString::new("the function cstr would not convert to rust str")
                                .expect("failed to convert incoming function string to internal string"),
        Ok(function) => function.to_owned(),
    };

    let argument_cstring = unsafe { CStr::from_ptr(argument_pointer) };

    let arguments = match argument_cstring.to_str() {
        Err(_) => return CString::new("the arguments cstr would not convert to rust string")
                                .expect("falide to convert incoming arguments string to internal string"),
        Ok(arguments) => arguments.to_owned(),
    };

    //might need to drop the pointed string somehow
    //drop(Box::from_raw(c_str))

    let output = switch(function, arguments);
    CString::new(output).expect("failed to convert outgoing internal string to CString")

}

// Java Interface
// https://github.com/dart-lang/sdk/projects/13#card-16918592
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
        let arguments = env.get_string(java_arguments).expect("invalid arguments string");
        let result = rusted(function.as_ptr(), arguments.as_ptr());
        let output = env.new_string(result.to_str().expect("failed to convert CSTring to str for jstring"))
            .expect("Couldn't create java string!");
        output.into_inner()

    }
}

//Important Stuff
#[cfg(test)]
mod tests {
    use super::*;


    fn clean_up_database() {
        match File::open("test.db") {
            Err(_) => (),
            Ok(_) => fs::remove_file("test.db").expect("failed to remove file after open succeeded")
        };
    }

    fn store_one() -> Result<(),()> {
        #[derive(Serialize)]
        struct ToInit {
            table: String,
            columns: String,
            path: String
        }

        let path = env::current_dir().expect("failed to get current directory");

        let this_data = ToInit {
            table: "names".to_string(),
            columns: "name TEXT NOT NULL".to_string(),
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");

        let output = init_storage(&input);
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        #[derive(Serialize)]
        struct ToStore {
            table: String,
            data: Vec<String>,
            path: String
        }

        let this_data = ToStore {
            table: "names".to_string(),
            data: vec!["TestCard".to_string()],
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");
        let output = store(&input);
        clean_up_database();
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }
        Ok(())
    }

    fn store_many() -> Result<(), ()> {
        #[derive(Serialize)]
        struct ToInit {
            table: String,
            columns: String,
            path: String
        }

        let path = env::current_dir().expect("failed to get current directory");

        let this_data = ToInit {
            table: "people".to_string(),
            columns: "name TEXT NOT NULL, birth_month TEXT NOT NULL".to_string(),
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");

        let output = init_storage(&input);
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        #[derive(Serialize)]
        struct ToStore {
            table: String,
            data: Vec<String>,
            path: String
        }

        let this_data = ToStore {
            table: "people".to_string(),
            data: vec!["Bob".to_string(), "May".to_string()],
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");
        let output = store(&input);
        clean_up_database();

        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        Ok(())
    }

    fn store_many_different() -> Result<(), ()> {
        #[derive(Serialize)]
        struct ToInit {
            table: String,
            columns: String,
            path: String
        }

        let path = env::current_dir().expect("failed to get current directory");

        let this_data = ToInit {
            table: "people".to_string(),
            columns: "name TEXT NOT NULL, birth_day INTEGER NOT NULL".to_string(),
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");

        let output = init_storage(&input);
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

/* please edit the associated text file and set path to your own for this test to pass*/
        //read this in from helper text file
        /*
        {
            "table": "people",
            "data": ["Bob", 14],
            "path": "/Users/j/Desktop/Code/rusty_flutter/rust"
        }
        */
        
        let input = fs::read_to_string("store_many_different.txt").expect("failed to read json input file");        
        println!("Input: {}", input);
        let output = store(&input);
        clean_up_database();

        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        Ok(())
    }
    
    #[test]
    #[serial(mut_database)]
    fn store_group() {
        store_one().expect("failed to do a succeessful store");
        store_many().expect("failed to successfully store many of the same type");
        store_many_different().expect("failed to successfully store many of different types");
    }

    fn search_one() -> Result<(),()> {
        #[derive(Serialize)]
        struct ToInit {
            table: String,
            columns: String,
            path: String
        }

        let path = env::current_dir().expect("failed to get current directory");

        let this_data = ToInit {
            table: "names".to_string(),
            columns: "name TEXT NOT NULL".to_string(),
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");

        let output = init_storage(&input);
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        #[derive(Serialize)]
        struct ToStore {
            table: String,
            data: Vec<String>,
            path: String
        }

        let this_data = ToStore {
            table: "names".to_string(),
            data: vec!["TestCard".to_string()],
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");
        let output = store(&input);
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        #[derive(Serialize)]
        struct ToSearch {
            query: String,
            data: Vec<String>,
            path: String
        };

        let this_data = ToSearch {
            query: "SELECT * FROM names WHERE name = ?".to_string(),
            data: vec!["TestCard".to_string()],
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");
        let output = search_storage(&input);
        if output.result != "Ok()" {
            println!("Err(): {:?}", output.data);
            return Err(());
        }

        Ok(())
    }

    #[test]
    #[serial(mut_database)]
    fn search_group() {
        search_one().expect("failed to get results from a search");
    }

    fn create_table_with_one_column() -> Result<(),()> {
        #[derive(Serialize)]
        struct ToInit {
            table: String,
            columns: String,
            path: String
        }

        let path = env::current_dir().expect("failed to get current directory");

        let this_data = ToInit {
            table: "names".to_string(),
            columns: "name TEXT NOT NULL".to_string(),
            path: path.display().to_string()
        };

        let input = serde_json::to_string(&this_data).expect("failed to encode the json string");

        let output = init_storage(&input);
        clean_up_database();
        assert_eq!(output.result, "Ok()");
        Ok(())
    }

    #[test]
    #[serial(mut_database)]
    fn create_group() {
        create_table_with_one_column().expect("failed to create a table with a single row");
    }
}