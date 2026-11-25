package agentguestbook

import "testing"

func TestNextStreak(t *testing.T) {
	if got := nextStreak(100, 101, 3); got != 4 {
		t.Fatalf("consecutive day: got %d, want 4", got)
	}
	if got := nextStreak(100, 105, 3); got != 1 {
		t.Fatalf("gap day: got %d, want 1", got)
	}
	if got := nextStreak(0, 20000, 0); got != 1 {
		t.Fatalf("first ever: got %d, want 1", got)
	}
}

func TestCheckInCountsOncePerDay(cur realm, t *testing.T) {
	res := CheckIn(cross(cur), "first message")
	if totalCheckIns != 1 || uniqueAgents != 1 {
		t.Fatalf("after first check-in: total=%d unique=%d, want 1/1", totalCheckIns, uniqueAgents)
	}
	if res == "" {
		t.Fatalf("empty result string")
	}

	// Same-day repeat: counters must not move, message must update.
	CheckIn(cross(cur), "updated message")
	if totalCheckIns != 1 || uniqueAgents != 1 {
		t.Fatalf("after same-day repeat: total=%d unique=%d, want 1/1", totalCheckIns, uniqueAgents)
	}
	// The key CheckIn stored under is the newest entry in the recent list;
	// read it back from realm state instead of assuming a frame address.
	if len(recent) != 1 {
		t.Fatalf("recent list length = %d, want 1", len(recent))
	}
	key := recent[0]
	stats, ok := getStats(key)
	if !ok {
		t.Fatalf("no stats stored for caller")
	}
	if stats.Message != "updated message" {
		t.Fatalf("message = %q, want %q", stats.Message, "updated message")
	}
	if stats.CurrentStreak != 1 || stats.TotalCheckIns != 1 {
		t.Fatalf("streak=%d total=%d, want 1/1", stats.CurrentStreak, stats.TotalCheckIns)
	}
}

func TestValidateMessage(t *testing.T) {
	// Exactly at the limit is fine.
	validateMessage(string(make([]byte, MaxMessageLength)))

	// One byte over the limit must panic. The check lives in a
	// non-crossing helper because panics raised across a realm
	// crossing cannot be recovered by the caller.
	defer func() {
		if recover() == nil {
			t.Fatalf("expected panic for oversized message")
		}
	}()
	long := make([]byte, MaxMessageLength+1)
	for i := range long {
		long[i] = 'a'
	}
	validateMessage(string(long))
}

func TestRenderShowsCounters(cur realm, t *testing.T) {
	CheckIn(cross(cur), "render probe")
	out := Render("")
	if totalCheckIns < 1 {
		t.Fatalf("expected at least one check-in")
	}
	found := false
	for _, want := range []string{"Agent Guestbook", "Total check-ins", "Check in"} {
		if !contains(out, want) {
			t.Fatalf("render output missing %q", want)
		}
		found = true
	}
	if !found {
		t.Fatalf("unreachable")
	}
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
