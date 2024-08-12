// SPDX-License-Identifier: Apache-2.0
module OpinionPoll {

    struct Poll has store {
        question: vector<u8>,
        options: vector<vector<u8>>,
        votes: vector<u64>,
        total_votes: u64,
        is_active: bool
    }

    struct Polls has store {
        polls: map<u64, Poll>,
        next_poll_id: u64 // Counter for generating unique IDs
    }

    struct Admins has store {
        admins: set<address>
    }

    // Creates a new poll
    public fun create_poll(
        admin: &signer,
        question: vector<u8>,
        options: vector<vector<u8>>,
    ) {
        let admin_address = signer::address_of(admin);

        // Check if the signer is an admin
        if !is_admin(admin_address) {
            panic("Only admin can create a poll");
        }

        let mut polls = borrow_global_mut<Polls>();
        let poll_id = polls.next_poll_id;
        polls.next_poll_id = poll_id + 1; // Increment ID for the next poll

        let new_poll = Poll {
            question,
            options,
            votes: vec![0; length(&options)],
            total_votes: 0,
            is_active: true,
        };

        polls.polls.insert(poll_id, new_poll);
    }

    // Votes for an option in a poll
    public fun vote(
        voter: &signer,
        poll_id: u64,
        option_index: u64
    ) {
        let mut polls = borrow_global_mut<Polls>();

        if !polls.polls.contains_key(&poll_id) {
            panic("Poll not found");
        }

        let poll = polls.polls.get_mut(&poll_id).unwrap();

        if !poll.is_active {
            panic("Poll is not active");
        }
        
        if option_index >= length(&poll.options) {
            panic("Invalid option index");
        }

        poll.votes[option_index] = poll.votes[option_index] + 1;
        poll.total_votes = poll.total_votes + 1;
    }

    // Ends a poll
    public fun end_poll(
        admin: &signer,
        poll_id: u64
    ) {
        let admin_address = signer::address_of(admin);

        if !is_admin(admin_address) {
            panic("Only admin can end the poll");
        }

        let mut polls = borrow_global_mut<Polls>();

        if !polls.polls.contains_key(&poll_id) {
            panic("Poll not found");
        }

        let poll = polls.polls.get_mut(&poll_id).unwrap();
        poll.is_active = false;
    }

    // Helper function to check if the address is an admin
    public fun is_admin(address: address): bool {
        let admins = borrow_global<Admins>();
        admins.admins.contains(&address)
    }

    // Fetches the poll details
    public fun get_poll_details(
        poll_id: u64
    ): (vector<u8>, vector<vector<u8>>, vector<u64>, u64, bool) {
        let polls = borrow_global<Polls>();

        if !polls.polls.contains_key(&poll_id) {
            panic("Poll not found");
        }

        let poll = polls.polls.get(&poll_id).unwrap();
        (
            poll.question,
            poll.options,
            poll.votes,
            poll.total_votes,
            poll.is_active
        )
    }

    // Fetches the votes for a specific option
    public fun get_votes(
        poll_id: u64,
        option_index: u64
    ): u64 {
        let polls = borrow_global<Polls>();

        if !polls.polls.contains_key(&poll_id) {
            panic("Poll not found");
        }

        let poll = polls.polls.get(&poll_id).unwrap();

        if option_index >= length(&poll.options) {
            panic("Invalid option index");
        }

        poll.votes[option_index]
    }

    // Initializes the global state (run once)
    public fun init() {
        let polls = Polls {
            polls: map::empty(),
            next_poll_id: 1 // Start IDs from 1
        };
        move_to<Polls>(polls);

        let admins = Admins {
            admins: set::empty()
        };
        move_to<Admins>(admins);
    }

    // Add an address as an admin (for initialization purposes)
    public fun add_admin(address: address) {
        let mut admins = borrow_global_mut<Admins>();
        admins.admins.insert(address);
    }
}
