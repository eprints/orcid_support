# set generic orcid report config that other reports can borrow
$c->{datasets}->{user}->{search}->{orcid_user_report} = $c->{search}->{user}; #use the default user search form

# sort options for sorting within each group
$c->{orcid_user_report}->{sortfields} = {
        "byname" => "name",
};

# export field options
$c->{orcid_user_report}->{exportfields} = {
        user_report_core => [ qw(
        userid
        username
        name
        orcid
        usertype
        email
        dept
        org                
    )],
};

$c->{orcid_user_report}->{exportfield_defaults} = [ qw(
        userid
        username
        name
        orcid
        usertype
        email
        dept
        org
)];

# AllUsersOrcid Report
$c->{plugins}{"Screen::Report::Orcid::AllUsersOrcid"}{params}{custom} = 1;
$c->{orcid_all_users}->{sortfields} = $c->{orcid_user_report}->{sortfields};
$c->{orcid_all_users}->{exportfields} = $c->{orcid_user_report}->{exportfields};
$c->{orcid_all_users}->{exportfield_defaults} = $c->{orcid_user_report}->{exportfield_defaults};
$c->{orcid_all_users}->{export_plugins} = $c->{user_report}->{export_plugins};
$c->{datasets}->{user}->{search}->{orcid_all_users} = $c->{search}->{user}; 

# UserOrcid Report
$c->{plugins}{"Screen::Report::Orcid::UserOrcid"}{params}{custom} = 1;
$c->{orcid_user}->{sortfields} = $c->{orcid_user_report}->{sortfields};
$c->{orcid_user}->{exportfields} = $c->{orcid_user_report}->{exportfields};
$c->{orcid_user}->{exportfield_defaults} = $c->{orcid_user_report}->{exportfield_defaults};
$c->{orcid_user}->{export_plugins} = $c->{user_report}->{export_plugins};
$c->{datasets}->{user}->{search}->{orcid_user} = $c->{search}->{user};

# CreatorsOrcid Report
$c->{plugins}{"Screen::Report::Orcid::CreatorsOrcid"}{params}{custom} = 1;
$c->{orcid_creators}->{sortfields} = $c->{eprint_report}->{sortfields};
$c->{orcid_creators}->{exportfields} = $c->{eprint_report}->{exportfields};
$c->{orcid_creators}->{exportfield_defaults} = $c->{eprint_report}->{exportfield_defaults};
$c->{orcid_creators}->{export_plugins} = $c->{eprint_report}->{export_plugins};
$c->{search}->{orcid_creators} = $c->{search}->{advanced};

# EditorsOrcid Report
$c->{plugins}{"Screen::Report::Orcid::EditorsOrcid"}{params}{custom} = 1;
$c->{orcid_editors}->{sortfields} = $c->{eprint_report}->{sortfields};
$c->{orcid_editors}->{exportfields} = $c->{eprint_report}->{exportfields};
$c->{orcid_editors}->{exportfield_defaults} = $c->{eprint_report}->{exportfield_defaults};
$c->{orcid_editors}->{export_plugins} = $c->{eprint_report}->{export_plugins};
$c->{search}->{orcid_editors} = $c->{search}->{advanced};
