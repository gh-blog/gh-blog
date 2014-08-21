function get_file_names {
    find -type f |
    egrep -v "/(node_modules)|(.git)/" | # Ignore node_modules and .git
    egrep -v '^./(tmp|posts|dist)/' | # Ignored dirs
    egrep -v '.(swp|ttf|txt|css|woff|eot|svg|png|jpe?g|sublime-.*)$' # Ignored file types
}

function get_loc {
    cat ${@} | wc -l
}

files=`get_file_names`;
echo Number of files: `echo $files | wc -w`
echo Lines of code: `get_loc $files`
