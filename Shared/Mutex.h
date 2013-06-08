//
//  Mutex.h
//  Stetho
//
//  Created by rsargent on 12/19/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#ifndef __Stetho__Mutex__
#define __Stetho__Mutex__

#include <pthread.h>

class Mutex {
private:
    pthread_mutex_t mutex;
public:
    Mutex() {
        mutex = PTHREAD_MUTEX_INITIALIZER;
    }
    void lock() {
        pthread_mutex_lock(&mutex);
    }
    void unlock() {
        pthread_mutex_unlock(&mutex);
    }
};

class ScopedLock {

private:
    Mutex &mutex;
    
public:
    ScopedLock(Mutex &m) : mutex(m) {
        mutex.lock();
    }

    ~ScopedLock() {
        mutex.unlock();
    }
};

#endif /* defined(__Stetho__ScopedMutex__) */
