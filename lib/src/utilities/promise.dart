import 'dart:async';

enum PromiseState {
  PENDING,
  FULFILLED,
  REJECTED,
}

class Promise {
  Promise(fn) {
    doResolve(fn, resolve, reject);
  }

  /// store state which can be PENDING, FULFILLED or REJECTED
  PromiseState state = PromiseState.PENDING;

  /// stores value or error once FULFILLED or REJECTED
  dynamic value;

  /// stores sucess & failure handlers attached by calling .then or .done
  List<dynamic> handlers = List();

  void fulfill(result) {
    state = PromiseState.FULFILLED;
    value = result;
    handlers.forEach(handle);
    handlers = null;
  }

  void reject(error) {
    state = PromiseState.REJECTED;
    value = error;
    handlers.forEach(handle);
    handlers = null;
  }

  void resolve(result) {
    try {
      var then = getThen(result);

      if (then != null) {
        doResolve(then, resolve, reject);
        return;
      }

      fulfill(result);
    } catch (error) {
      reject(error);
    }
  }

  void handle(handler) {
    if (state == PromiseState.PENDING) {
      handlers.add(handler);
    } else {
      if (state == PromiseState.FULFILLED && handler.onFulfilled is Function) {
        handler.onFulfilled(value);
      }

      if (state == PromiseState.REJECTED && handler.onRejected is Function) {
        handler.onRejected(value);
      }
    }
  }

  void done(onFulfilled, onRejected) {
    // ensure we are always asynchronous
    Timer.run(() {
      handle({'onFulfilled': onFulfilled, 'onRejected': onRejected});
    });
  }

  Promise then(onFulfilled, onRejected) {
    var self = this;

    return Promise((resolve, reject) {
      return self.done((result) {
        if (onFulfilled is Function) {
          try {
            return resolve(onFulfilled(result));
          } catch (ex) {
            return reject(ex);
          }
        } else {
          return resolve(result);
        }
      }, (error) {
        if (onRejected is Function) {
          try {
            return resolve(onRejected(error));
          } catch (ex) {
            return reject(ex);
          }
        } else {
          return reject(error);
        }
      });
    });
  }
}

/// Check if a value is a Promise and, if it is, return the `then` method of that promise.
Function getThen(value) {
  if (value != null && value is Future) {
    var then = value.then;

    if (then is Function) {
      return then;
    }
  }

  return null;
}

/// Take a potentially misbehaving resolver function and make sure
/// onFulfilled and onRejected are only called once.
///
/// Makes no guarantees about asynchrony.
void doResolve(
  Function fn,
  Function onFulfilled,
  Function onRejected,
) {
  var done = false;

  try {
    fn((value) {
      if (done) {
        return;
      }

      done = true;
      onFulfilled(value);
    }, (reason) {
      if (done) {
        return;
      }

      done = true;
      onRejected(reason);
    });
  } catch (ex) {
    if (done) {
      return;
    }

    done = true;
    onRejected(ex);
  }
}
