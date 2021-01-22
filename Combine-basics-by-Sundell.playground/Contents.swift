// Follow along with https://www.swiftbysundell.com/basics/combine/

import Combine
import Foundation

// 1. Basics

guard let url = URL(string: "https://api.github.com/repos/clarknt/combine-basics") else {
    preconditionFailure("Invalid URL")
}

let publisher =
    // perform request
    URLSession.shared.dataTaskPublisher(for: url)
    // extract data property from request returned value
    .map { $0.data } // or map(\.data)
    // decode JSON data
    .decode(type: Repository.self, decoder: JSONDecoder())
    // switch to main thread to update UI if needed (leads to a lock in playgrounds)
    //.receive(on: DispatchQueue.main)

struct Repository: Codable {
    let name: String
    let description: String
    let html_url: String
    
    var prettyfied: String {
        """
           
           Name: \(name)
           Description: \(description)
           URL: \(html_url)
        """
    }
}

let cancellable = publisher.sink(
    // called once when the publisher was completed
    receiveCompletion: { completion in
        switch(completion) {
        case .failure(let error):
            print("Failure: \(error)")
        case .finished:
            print("Success performing URL request and decoding result")
        }
    },
    // called each time a new value is emitted
    receiveValue: { repository in 
        print("Repository: \(repository.prettyfied)")   
    })

// 2. Custom publisher

class Counter {
    // this publisher allows external code to publish (send) values,
    // which is not wanted
    //let publisher = PassthroughSubject&lt;Int, Never&gt;()
    
    // let's make a private one instead
    // "Never" means no error will be thrown
    private(set) var subject = PassthroughSubject<Int, Never>()
    
    // and create a publisher that erases our actual publisher,
    // effectively removing the send() method
    var publisher: AnyPublisher<Int, Never> {
    subject.eraseToAnyPublisher()
    }
    
    private(set) var value = 0 {
        didSet {
            subject.send(value)
        }
    }
    
    func increment() {
        value += 1
    }
}

let counter = Counter()

let counterCancellable =
    counter.publisher
    // start sending values above 2 only
    .filter { $0 > 2 }
    .sink { value in
        print("New counter value: \(value)")
    }

counter.increment()
counter.increment()
counter.increment()

// sleep otherwise the playground exits before the request completes
sleep(10)
