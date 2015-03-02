
watch = (object, parent, config) ->

    unless object instanceof Object
        return object

    common = {
        parent: parent
        config: config
    }

    if Object.getOwnPropertyDescriptor object, '__observable__'
        object.set.parent parent
        return object

    else if object.constructor is Object
        return setup_object object, common

    else if object.constructor is Array
        return setup_array object, common

    else
        return object

setup_common = (object, common) ->

    common.observable = null
    common.callbacks = {}
    common.callbacks.object_change = []
    common.timeouts = {}

    ### set(key, value)
        allows the user to set a property that could not be instrumented otherwise. 
        e.g. a new object property or an array index
    ###
    common.set = (key, value) ->

        result = common.set.silently key, value
        common.trigger.change()

        return result

    common.set.silently = (key, value) ->
        common.observable[key] = watch value, common.observable, common.config

    common.set.deeply = (deep_object) ->

        for key, value of deep_object

            if value instanceof Object and common.observable[key]?
                common.observable[key].set.deeply value

            else
                common.set key, value

        return common.observable

    common.set.parent = (parent) ->
        common.parent = parent

    common.on = {}

    ### on.change(callback)
        allows the user to register a callback against changes to the current object
        Calls 'callback' every time the current object sees a change within it
        (key, callback) ->
    ###
    common.on.change = (callback) ->
        common.callbacks.object_change.push callback
        return -> remove_from_list common.callbacks.object_change, callback

    common.run_callbacks = (callbacks, timeouts, name, args) ->

        if callbacks[name].length

            timeouts[name] ?= setTimeout ->

                for callback in callbacks[name]
                    callback.apply common.observable, args

                delete timeouts[name]

    common.trigger = {}

    ### trigger.change()
        Triggers the callbacks associated with the current object
    ###
    common.trigger.change = ->
        common.run_callbacks common.callbacks, common.timeouts, 'object_change', [ common.observable ]
        common.parent?.trigger.change()

setup_object = (object, common) ->

    setup_common object, common

    common.observable = {}
    common.underlying_data = {}
    common.callbacks.key_change = {}
    common.timeouts.key_change = {}

    common.setup = (key) ->

        return if common.callbacks.key_change[key]?

        common.callbacks.key_change[key] = []

        Object.defineProperty common.observable, key, {

            get: -> common.underlying_data[key]
            set: (data) -> common.set key, data

            enumerable: true
        }

    do (old = common.set) ->

        common.set = (key, value) ->
            
            common.setup key
            result = common.set.silently key, value
            common.trigger.change key

            return result

        for key, value of old
            common.set[key] = value
    
    common.set.silently = (key, value) ->
        common.underlying_data[key] = watch value, common.observable, common.config

    ### on.change(key, callback)
        Calls 'callback' every time the key 'key' is changed on the current object
        If 'key' does not exist within the observable POJO, it is registered
    ###
    do (old = common.on.change) -> common.on.change = (key, callback) ->

        if arguments.length == 1
            old key

        else
            common.setup key
            common.callbacks.key_change[key].push callback

            return -> remove_from_list common.callbacks.key_change[key], callback

    ### trigger.change(key)
        Triggers the callbacks associated with the current object's key 'key'
    ###
    do (old = common.trigger.change) -> common.trigger.change = (key) ->

        if arguments.length == 1

            unless common.callbacks.key_change[key]?
                throw new Error("key '${key}' does not exist")

            common.run_callbacks(
                common.callbacks.key_change,
                common.timeouts.key_change,
                key,
                [ common.underlying_data[key], common.observable ]
            )

        old()

    for key, value of object
        common.set.silently key, value
        common.setup key

    return instrument_object common

setup_array = (array, common) ->

    setup_common array, common

    common.observable = []

    for value, index in array
        common.set.silently index, value

    for method in [ 'pop', 'push', 'reverse', 'shift', 'unshift', 'splice', 'sort' ]

        Object.defineProperty common.observable, method, value: do (method) -> ->
            common.trigger.change()
            Array.prototype[method].apply common.observable, arguments

    return instrument_object common

instrument_object = (common) ->

    for method in [ 'set', 'on', 'trigger' ]
        Object.defineProperty common.observable, method, value: common[method]

    if common.config.debug
        Object.defineProperty common.observable, 'common', value: common

    # Mark this object as observable
    Object.defineProperty common.observable, '__observable__', value: undefined

    return common.observable

remove_from_list = (list, item) ->
    list.splice list.indexOf(item), 1

configure = (default_config) ->

    look_at_that = (pojo) -> watch pojo, undefined, default_config

    look_at_that.configure = (config) ->

        for key, value of default_config
            config[key] ?= value

        return configure config

    return look_at_that

### watch(object)
    Takes in a POJO and makes it observable
###
module.exports = configure {}
