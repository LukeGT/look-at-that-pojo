
remove_from_list = (list, item) ->
    list.splice list.indexOf(item), 1

watch = (object, parent) ->

    unless object instanceof Object
        return object

    if object instanceof Array
        console.error "WARNING: Arrays not supported"
        return object

    underlying_data = {}
    observable = {}
    object_change_callbacks = []
    key_change_callbacks = {}

    fire_key_change_callbacks = (key, data) ->

        for callback in key_change_callbacks[key]
            callback.call observable, data, observable

        return undefined

    fire_object_change_callbacks = ->

        for callback in object_change_callbacks
            callback.call observable, observable

        return undefined

    setup = (key) ->

        key_change_callbacks[key] ?= []

        return if Object.getOwnPropertyDescriptor observable, key

        Object.defineProperty observable, key, {

            get: -> underlying_data[key]

            set: (data) ->

                underlying_data[key] = watch data, observable

                fire_key_change_callbacks(key, data)
                fire_object_change_callbacks()
                parent?.trigger.change()

            enumerable: true
        }

    for key, value of object
        underlying_data[key] = watch value, observable
        setup key
    
    Object.defineProperty observable, 'set', {

        ### set(key, value)
            allows the user to set a property that did not exist in the original POJO
        ###
        value: (key, value, silent = false) ->

            unless arguments.length >= 2 and arguments.length <= 3
                throw new Error("set takes 2 or 3 arguments")

            setup key

            if silent
                underlying_data[key] = value
            else
                observable[key] = value
    }

    Object.defineProperty observable, 'on', {

        value: {

            ### on.change(...)
                allows the user to register a callback against changes to the current object
                (callback) ->
                    Calls 'callback' every time the current object sees a change within it
                (key, callback) ->
                    Calls 'callback' every time the key 'key' is changed on the current object
                    If 'key' does not exist within the observable POJO, it is registered
            ###
            change: ->

                if arguments.length == 1

                    [ callback ] = arguments

                    object_change_callbacks.push callback

                    return -> remove_from_list object_change_callbacks, callback

                else if arguments.length == 2

                    [ key, callback ] = arguments

                    setup key
                    key_change_callbacks[key].push callback

                    return -> remove_from_list key_change_callbacks[key], callback

                else
                    throw new Error("on.change must take 1 or 2 arguments")


        }
    }

    Object.defineProperty observable, 'trigger', {

        value: {

            ### trigger.change(...)
                ->
                    Triggers the callbacks associated with the current object
                (key) ->
                    Triggers the callbacks associated with the current object's key 'key'
            ###
            change: (key) ->

                if arguments.length == 1

                    unless key_change_callbacks[key]?
                        throw new Error("key '${key}' does not exist")

                    fire_key_change_callbacks(key, underlying_data[key])

                if arguments.length <= 1
                    fire_object_change_callbacks()
                    parent?.trigger.change()

                else
                    throw new Error("trigger.change must take no more than 1 argument")
        }
    }

    return observable

### watch(object)
    Takes in a POJO and makes it observable
###
module.exports = (pojo) -> watch pojo