# Look at that POJO

Observe POJOs while using POJOs like POJOs

``` javascript
var look_at_that = require('look-at-that-pojo')

var pojo = {
  some: 'plain',
  old: 'properties',
  in: {
    a: 'plain',
    old: {
      javascript: 'object',
    }
  }
}

// The original POJO remains untouched
// We interact with the observable object as if it was the original POJO
var observable = look_at_that(pojo)

// For all intents and purposes, it behaves the same as the POJO
JSON.stringify(pojo) === JSON.stringify(observable) // true

// Except that we can listen to changes in any part of the object

observable.on.change(function() {
  console.log('This will pick up any changes throughout the observable object')
})

observable.in.on.change(function() {
  console.log('This will only pick up changes in the observable.in object')
})

observable.in.on.change('a', function(value) {
  console.log('This will pick up on changes to observable.in.a')
})

// All change events above fire
observable.in.a = 5

// Only the first two change events fire
observable.in = {
  this: 'becomes',
  observable: 'automatically',
}

// Only the first change event fires
observable.old = 10
```