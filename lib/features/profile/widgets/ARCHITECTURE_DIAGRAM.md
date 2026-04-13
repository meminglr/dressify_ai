# FlexibleSpaceBarWidget Architecture

## Component Hierarchy

```
ProfileScreen (Task 11 - Not yet implemented)
│
└── CustomScrollView
    │
    ├── SliverAppBar
    │   │
    │   └── FlexibleSpaceBarWidget ✅ (Task 10 - COMPLETED)
    │       │
    │       └── FlexibleSpaceBar
    │           │
    │           └── Background Stack
    │               │
    │               ├── Cover Image Layer
    │               │   ├── NetworkImage (if coverImageUrl exists)
    │               │   └── Default Gradient (fallback)
    │               │
    │               ├── Gradient Overlay Layer
    │               │   └── LinearGradient (transparent → dark)
    │               │
    │               └── Profile Info Layer
    │                   │
    │                   └── ProfileInfoSection ✅ (Task 5.2 - COMPLETED)
    │                       │
    │                       ├── CircleAvatar (80px)
    │                       ├── Full Name (Manrope 36px)
    │                       ├── Bio (Be Vietnam Pro 14px)
    │                       └── StatsOverlay ✅ (Task 5.1 - COMPLETED)
    │                           ├── AI Looks Count
    │                           ├── Uploads Count
    │                           └── Models Count
    │
    ├── SliverPersistentHeader (Task 11.3)
    │   └── ProfileTabBar ✅ (Task 6 - COMPLETED)
    │
    ├── SliverToBoxAdapter (Task 11.4)
    │   └── PrimaryActionButton ✅ (Task 5.4 - COMPLETED)
    │
    └── SliverGrid (Task 11.5)
        └── MasonryGridView ✅ (Task 7 - COMPLETED)
            └── GridItem ✅ (Task 5.3 - COMPLETED)
```

## Data Flow

```
Profile Model ✅
├── id: String
├── fullName: String
├── username: String
├── bio: String?
├── avatarUrl: String?
└── coverImageUrl: String? ──────┐
                                  │
UserStats Model ✅                │
├── aiLooksCount: int             │
├── uploadsCount: int             │
└── modelsCount: int              │
                                  │
                                  ▼
                    FlexibleSpaceBarWidget
                    ├── Uses coverImageUrl for background
                    ├── Passes profile to ProfileInfoSection
                    └── Passes stats to ProfileInfoSection
                                  │
                                  ▼
                        ProfileInfoSection
                        ├── Uses avatarUrl for avatar
                        ├── Uses fullName for name display
                        ├── Uses bio for bio display
                        └── Passes stats to StatsOverlay
                                  │
                                  ▼
                            StatsOverlay
                            ├── Displays aiLooksCount
                            ├── Displays uploadsCount
                            └── Displays modelsCount
```

## Scroll Behavior

```
Scroll Position: Top (Expanded)
┌─────────────────────────────────────┐
│                                     │
│         Cover Image (480px)         │
│      with Gradient Overlay          │
│                                     │
│                                     │
│         ┌─────────────┐             │
│         │   Avatar    │             │
│         └─────────────┘             │
│         Alex Rivera                 │
│    Digital Fashion Curator          │
│                                     │
│    ┌───────────────────────┐       │
│    │  24    12      8      │       │
│    │ Looks Uploads Models  │       │
│    └───────────────────────┘       │
│                                     │
└─────────────────────────────────────┘
              ▼ Scroll Down
┌─────────────────────────────────────┐
│                                     │
│    Partially Collapsed (240px)      │
│      with Parallax Effect           │
│                                     │
│         ┌─────────────┐             │
│         │   Avatar    │             │
│         └─────────────┘             │
│         Alex Rivera                 │
│                                     │
└─────────────────────────────────────┘
              ▼ Scroll Down
┌─────────────────────────────────────┐
│  Collapsed AppBar (56px)            │
│  [Back] Alex Rivera        [⚙️]     │
└─────────────────────────────────────┘
```

## Animation Details

### Parallax Effect
- **collapseMode**: `CollapseMode.parallax`
- **Effect**: Background scrolls slower than foreground
- **Result**: Smooth, premium feel during scroll

### Opacity Transitions
- Profile info fades out as header collapses
- Cover image maintains visibility throughout
- Gradient overlay remains constant

### Height Transitions
- **Expanded**: 480px (full profile view)
- **Transitioning**: 480px → 56px (smooth animation)
- **Collapsed**: 56px (compact app bar)

## Integration Status

### ✅ Completed Components
1. **Profile Model** (Task 1)
2. **UserStats Model** (Task 1)
3. **StatsOverlay Widget** (Task 5.1)
4. **ProfileInfoSection Widget** (Task 5.2)
5. **FlexibleSpaceBarWidget** (Task 10) ← Current

### 🔄 Pending Components
1. **ProfileScreen** (Task 11) - Will integrate FlexibleSpaceBarWidget
2. **SliverPersistentHeader with TabBar** (Task 11.3)
3. **Full scroll behavior** (Task 11)

## Design Specifications Applied

### From Figma Design
- ✅ Expanded Height: 480px
- ✅ Collapsed Height: 56px
- ✅ Gradient: transparent → rgba(0,0,0,0.7)
- ✅ Shadow: 0px 25px 50px -12px rgba(0,0,0,0.25)
- ✅ Border Radius: 40px (bottom corners)
- ✅ Primary Color: #742fe5
- ✅ Primary Light: #ceb5ff

### Typography (via ProfileInfoSection)
- ✅ Name: Manrope Regular, 36px, -0.9px letter spacing
- ✅ Bio: Be Vietnam Pro Medium, 14px

### Spacing
- ✅ Profile info positioned 32px from bottom
- ✅ Proper padding and margins throughout

## Performance Considerations

### Optimizations Applied
1. **Const Constructors**: Used where possible
2. **Efficient Image Loading**: NetworkImage with caching
3. **Lazy Rendering**: Only renders visible content
4. **Minimal Rebuilds**: Stateless widget design

### Future Optimizations (in ProfileScreen)
1. **RepaintBoundary**: Around FlexibleSpaceBar
2. **Selective Rebuilds**: Using Consumer widgets
3. **Image Preloading**: For cover images

## Testing Coverage

### Unit Tests ✅
- Widget creation
- Data passing
- Height constants
- Collapse mode

### Widget Tests ✅
- ProfileInfoSection integration
- Cover image handling
- Default background
- Border radius

### Integration Tests (Future)
- Scroll behavior
- Animation smoothness
- State transitions

## Next Implementation Steps

1. **Task 11.1**: Create ProfileScreen basic structure
2. **Task 11.2**: Integrate FlexibleSpaceBarWidget into SliverAppBar
3. **Task 11.3**: Add TabBar as SliverPersistentHeader
4. **Task 11.4**: Add PrimaryActionButton
5. **Task 11.5**: Add MasonryGridView
6. **Task 11.6**: Add loading/error/empty states
7. **Task 11.7**: Add pull-to-refresh
8. **Task 11.8**: Add accessibility support
