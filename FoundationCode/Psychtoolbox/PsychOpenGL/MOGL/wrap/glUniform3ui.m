function glUniform3ui( location, v0, v1, v2 )

% glUniform3ui  Interface to OpenGL function glUniform3ui
%
% usage:  glUniform3ui( location, v0, v1, v2 )
%
% C function:  void glUniform3ui(GLint location, GLuint v0, GLuint v1, GLuint v2)

% 30-Sep-2014 -- created (generated automatically from header files)

if nargin~=4,
    error('invalid number of arguments');
end

moglcore( 'glUniform3ui', location, v0, v1, v2 );

return
