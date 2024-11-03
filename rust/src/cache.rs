pub struct Cache<T, F> where F: Fn() -> Option<T> {
    value: Option<T>,
    default_value: T,
    producer: F
}

impl<T, F> Cache<T, F> where F: Fn() -> Option<T> {
    
    pub fn get(&mut self) -> &T {
        if self.value.is_none() {
            let produced = (self.producer)();
            if produced.is_some() {
                self.value = produced;
            }
        }
        
        self.value.as_ref().unwrap()
    }
    
}
