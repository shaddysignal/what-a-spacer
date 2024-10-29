use godot::prelude::GodotConvert;
use godot::builtin::GString;

#[macro_export]
macro_rules! ordered_string_enum {
    (enum $name:ident default $default:ident {
        $($variant:ident = $val:expr),*
    }) => {
        #[derive(GodotConvert, Debug, Ord, Eq, PartialOrd, PartialEq)]
        #[godot(via = GString)]
        pub enum $name {
            $($variant),*
        }        

        impl std::fmt::Display for $name {
            fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
                let signal_string: String = match self {
                    $($name::$variant => $val.into()),*
                };

                write!(f, "{}", signal_string)
            }
        }
        
        impl Default for $name {
            fn default() -> Self {
                $name::$default
            }
        }
    };
}

#[test]
fn test_ordered_string_enum() {
    ordered_string_enum! {
        enum A default Ta {
            Ba = "BA",
            Ca = "CA",
            Ta = "TA",
            Aa = "AA"
        }
    }
    
    assert!(A::Aa >= A::Aa);
    assert!(A::Ta <= A::Aa);
}