import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Option "mo:base/Option";

actor {
    // public type Message = Text;
    public type Message = {
        text:Text;
        time:Time.Time;
    };

    public type Microblog = actor {
        follow: shared (Principal) -> async ();
        follows: shared query () -> async ();
        post: shared (Text) -> async ();
        posts: shared query (since :?Time.Time) -> async [Message];
        timeline: shared (since:?Time.Time) -> async [Message];
    };
    
    stable var followed : List.List<Principal> = List.nil();

    public shared func follow(id:Principal) : async () {
        //TEST
        //assert(Principal.toText(msg.caller) == "2bvgb-udj2c-iikgg-hputo-cu5af-fiu7v-3gpsi-p5e5e-l4ucs-ptatd-uqe");
        followed := List.push(id,followed)
    };

    public shared query func follows() : async [Principal] {
        List.toArray(followed)
    };

    stable var messages : List.List<Message> = List.nil();

    public shared (msg) func post(str:Text) : async () {
        assert(Principal.toText(msg.caller) == "2bvgb-udj2c-iikgg-hputo-cu5af-fiu7v-3gpsi-p5e5e-l4ucs-ptatd-uqe");
        let now = Time.now();
        let m = {
            text=str;
            time=Time.now()
            };

        messages := List.push(m,messages);
    };

    public shared query func posts(since :?Time.Time) : async [Message]{
        switch (since) {
            case (null) {
                List.toArray(messages);
            };
            case (?time) {
                let f = List.filter<Message>(messages,func(e){e.time>=time});
                List.toArray(f);
            };
        }
    };

    public shared func timeline(since:?Time.Time) : async [Message] {
        var all : List.List<Message> = List.nil();
        
        for(id in Iter.fromList(followed)) {
            let canister :Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for (msg in Iter.fromArray(msgs)) {
                all := List.push(msg,all);
            };
        };
        List.toArray(all);
    }

};
