# Legacy Event Selection Methods

These are older event selection and epoching functions that are not used by the current main tools (JuanAnalyzer, EEGQualityAnalyzer) but are kept for backwards compatibility or reference.

## Files

### Event Selection
- **autoSelectTrialEvents.m** - Original auto event selection
- **autoSelectTrialEventsGrouped.m** - Grouped event selection variant

### Epoching Functions
- **epochEEGByEvents.m** - Basic event-based epoching
- **epochEEGByEventsGrouped.m** - Grouped event epoching
- **epochEEGByMarkerPairs.m** - Epoch by start/end marker pairs

## Status

⚠️ **Legacy Code** - These functions are superseded by:
- `autoSelectTrialEventsUniversal.m` (in JuanAnalyzer/)
- `epochEEGByEventsUniversal.m` (in JuanAnalyzer/)

## Usage

These functions may still work but are not actively maintained. They are kept for:
- Reference implementations
- Backwards compatibility with old scripts
- Comparison with newer universal methods

If you have old scripts that use these functions, they should still work, but consider migrating to the universal versions in JuanAnalyzer for better AI integration and practice trial filtering.
