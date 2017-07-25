//: Playground - noun: a place where people can play

import UIKit
func doWorkAsync(block: @escaping ()->()) {
    DispatchQueue.main.async {
        block()
    }
}
func doWork(block: ()->()) {
    block()
}

doWork {
    print("work")
}

class S {
    var foo = "foo"
    
    func method1() {
        doWork {
            print(foo)
        }
        foo = "bar"
    }
    
    func method2() {
        doWorkAsync {
            print(self.foo)
        }
        foo = "bar"
    }
}

S().method1() // foo
S().method2() // bar