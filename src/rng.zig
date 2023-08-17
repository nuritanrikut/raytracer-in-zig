pub const random_number_generator_t = struct {
    state: i32,
    div: i32,
    mod: i32,

    pub fn init() random_number_generator_t {
        return random_number_generator_t{
            .state = 675248,
            .div = 1000,
            .mod = 1000000,
        };
    }

    pub fn clone(self: *random_number_generator_t) random_number_generator_t {
        return random_number_generator_t{
            .state = self.state,
            .div = self.div,
            .mod = self.mod,
        };
    }

    fn next(self: *random_number_generator_t) i32 {
        const state_sq: i64 = @as(i64, self.state) * self.state;
        const state_sq_div: i64 = @divFloor(state_sq, self.div);
        const state_mod: i64 = @mod(state_sq_div, self.mod);
        const state: i32 = @intCast(state_mod);
        self.state = state;
        return state;
    }

    pub fn random_f64(self: *random_number_generator_t) f64 {
        const t1: f64 = @floatFromInt(self.next());
        const t2: f64 = @floatFromInt(self.next());
        const m: f64 = @floatFromInt(self.mod);
        return ((t1 * m + t2) / m) / m;
    }

    pub fn random_range(self: *random_number_generator_t, min: f64, max: f64) f64 {
        return min + (max - min) * self.random_f64();
    }
};