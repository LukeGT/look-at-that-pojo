# Look at that POJO

Observe POJOs while using POJOs like POJOs

There are plenty of libraries out there that let you maintain models and listen to change events on their properties, like Backbone's Model class.  But how annoying is it having to use their "get" and "set" methods, *right*?

This library does away with that nonsense and lets you use your plain old javascript objects just like you used to, while still being able to listen carefully on changes at any part of the object.  

## The basics

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

// All change events above fire when we set this property's value
observable.in.a = 5

// Only the first two change events fire when we change this property's value
observable.in = {
  this: 'becomes',
  observable: 'too',
}

// Only the first change event fires when we set this
observable.old = 10
```

## What works and what doesn't

``` javascript
var look_at_that = require('look-at-that-pojo')

observable = look_at_that({
    exists: true,
    object: {
        key: 'value',
    },
    array: [key: 'value', 1, 2, 3],
    non_pojo: new String('not a pojo')
})


// WORKS: Listening for a property that doesn't exist yet
observable.on.change('does_not_exist', function() {
    console.log('This works')
})
observable.does_not_exist = false


// DOESN'T WORK: Changing a key that didn't exist and listening on a parent object
observable.on.change(function(){
  console.log('I only catch events for properties that are instrumented')
})
observable.something = 'not cool'


// WORKS: Changing a key that didn't exist using .set() and listening on a parent object
observable.on.change(function(){
  console.log('Luckily .set() adds intrumentation for me!')
})
observable.set('something', 'really cool')


// DOESN'T WORK: Listening to a key change and changing something within the key's object
observable.on.change('object', function() {
    console.log('Key changes dont propagate. You should use observable.object.on.change instead!')
})
observable.object.key = 'a different value'


// WORKS: Listening on a property that was added after creation
observable.exists = {
    new: 'object'
}
observable.exists.new.on.change(function() {
    console.log('This works')
})
observable.exists.new = 'woo!'


// DOESN'T WORK: Listening to a deep property, and then setting the parent object to a new object
observable.object.on.change(function() {
    console.log('This wont fire because the instrumented object is about to get blown away')
})
observable.object = {
    key: 'new value'
}


// WORKS: Listening to a deep property, then setting the parent object deeply, retaining all instrumentation and firing all relevant events


observable.object.on.change(function() {
    console.log('I will fire!')
})
observable.object.set.deeply({
    key: 'new value'
})


// DOESN'T WORK: Trying to listen for changes on things that aren't technically Objects
observable.exists.on.change(function(){
    console.log("observable.exists is a boolean, and so cannot be" +
    "instrumented without screwing around with the Object prototype..." +
    "You should use observable.on.change('exists', ...) instead.")
})


// WORKS: Nesting observables in observables
other_observable = look_at_that({ other: 'object' })
observable.object = other_observable
observable.on.change(function() {
    console.log('This will be called')
})
other_observable.on.change(function() {
    console.log('And so will this!')
})
observable.object.other = 'something'
other_observable.other === 'something' // true


// DOESNT WORK: Things that aren't plain old javascript objects
// (this is sort of a feature... we could return an instrumented object that looks like your specialised object at face value, but it won't behave the same when you run its methods or look for properties that belong in its prototype)
observable.non_pojo.on.change(function(){ console.log('I cant get here, "on" is undefined') })
observable.non_pojo instanceof String // This is true


// WORKS: Arrays
observable.array.on.change(function(){ console.log('This totally works') })
observable.array.push(4) // Works for any destructive array function
observable.array.set(5, 5) // Works for any index assignments
observable.array[0].key = true // Nested objects are observable
```

## Keeping quiet

``` javascript
observable.on.change(function(){ console.log('I wont fire') })
observable.set.silently('property', 'value')
```

## Removing handlers

``` javascript
remove = observable.on.change(function(){ console.log('I dont even want to fire') })
observable.property = 'value' // Change event is fired
remove()
observable.property = 'value' // Nothing is fired
```

## Triggering events

``` javascript
observable.on.change(function(){ console.log('object change') })
observable.on.change('key', function(){ console.log('key change') })

observable.trigger() // object change triggered
observable.trigger('key') // key change triggered
```
